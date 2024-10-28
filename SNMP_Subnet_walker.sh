#!/bin/bash

input_csv="$1"
today=$(date +"%m%d%y")
community_file="community_strings.txt"

declare -A oids=(
    [".1.3.6.1.2.1.1.1.0"]="sysDescr"
    [".1.3.6.1.2.1.1.2.0"]="sysObjectID"
    [".1.3.6.1.2.1.1.4.0"]="sysContact"
    [".1.3.6.1.2.1.1.5.0"]="sysName"
    [".1.3.6.1.2.1.1.6.0"]="sysLocation"
)

validate_cidr() {
    local cidr_regex='^([0-9]{1,3}\.){3}[0-9]{1,3}/([0-9]|[1-2][0-9]|3[0-2])$'
    [[ $1 =~ $cidr_regex ]] && return 0 || return 1
}

echo "Starting fping SNMP audit script..."

if [[ ! -f "$community_file" ]]; then
    echo "Error: Community strings file ($community_file) not found. Please create it or use fping_auditer_snmp_string_updater.sh to add SNMP communities."
    exit 1
fi

if [[ -z "$input_csv" ]]; then
    echo " "
    echo "------------------------------------------"
    echo "Input Exception: No CSV file provided."
    echo "------------------------------------------"
    echo "If you want to run this in bulk, provide a CSV file in this format:"
    echo " "
    echo "Network - Specific,Network - Supernet,Description"
    echo "Example: 192.168.1.0/30,192.168.0.0/16,Test Network"
    echo "------------------------------------------" 
    echo "Alternatively, enter a single subnet to run this script against (e.g., x.x.x.x/24):"
    echo " " 
    echo "------------------------------------------"
    read -p "Enter a valid subnet in CIDR format: " input_subnet
    echo " " 
    if ! validate_cidr "$input_subnet"; then
        echo "Invalid subnet format. Please use CIDR notation (e.g., 192.168.1.0/24). Exiting."
        exit 1
    fi
else
    if [[ ! -f "$input_csv" || "${input_csv##*.}" != "csv" ]]; then
        echo "Error: Please provide a valid .csv file as input."
        echo "Usage: $0 <filename.csv>"
        exit 1
    fi
fi

base_folder="${input_csv%.csv}"
if [[ -z "$input_csv" ]]; then
    mkdir -p "SingleSubnetAudit"
    subnet_mask=$(echo "$input_subnet" | tr '/' '_')
    output_csv="SingleSubnetAudit/${today}_${subnet_mask}.csv"
else
    dated_folder="${base_folder}/${today}"
    mkdir -p "$dated_folder"
    output_csv="${dated_folder}/updated_${input_csv:-SingleSubnetAudit}.csv"
fi

header="Network - Specific,IP Address,Community String"
for oid_name in "${oids[@]}"; do
    header+=",${oid_name}"
done
echo "$header" > "$output_csv"

process_ip() {
    local specific="$1"
    local ip="$2"
    local community_string=""
    local device_info=""

    echo "Processing IP: $ip..."

    while read -r community; do
        device_info=""
        echo "Trying community string '$community' on $ip with SNMPv2c..."
        
        for oid in "${!oids[@]}"; do
            value=$(snmpget -v2c -c "$community" "$ip" "$oid" -Oqv 2>/dev/null)
            device_info+="${value:-NA},"
        done
        
        if [[ "$device_info" != "NA,NA,NA,NA,NA," ]]; then
            community_string="$community"
            echo "$specific,$ip,$community_string,${device_info%,}" >> "$output_csv"
            echo "IP $ip processed with SNMP data using community: $community_string"
            return
        else
            echo "No SNMP data available for IP $ip with community '$community'."
        fi
    done < "$community_file"

    if [[ -z "$community_string" ]]; then
        device_info=$(for i in "${oids[@]}"; do echo -n "NA,"; done)
        echo "$specific,$ip,No Community String,${device_info%,}" >> "$output_csv"
        echo "IP $ip processed: No SNMP data available with any community."
    fi
}

if [[ -n "$input_csv" ]]; then
    echo "Processing CSV file: $input_csv"
    tail -n +2 "$input_csv" | while IFS=',' read -r specific supernet description; do
        specific=$(echo "$specific" | xargs)
        echo "Pinging network $specific..."
        alive_ips=$(fping -a -g "$specific" 2>/dev/null | sort -u)

        if [[ -n "$alive_ips" ]]; then
            echo "Found $(echo "$alive_ips" | wc -l) responsive IP(s) in $specific"
            for ip in $alive_ips; do
                process_ip "$specific" "$ip" &
                while (( $(jobs | wc -l) >= 5 )); do sleep 1; done
            done
            wait
        else
            echo "No responsive IPs found in $specific"
        fi
    done
else
    specific="$input_subnet"
    echo "Pinging network $specific..."
    alive_ips=$(fping -a -g "$specific" 2>/dev/null | sort -u)

    if [[ -n "$alive_ips" ]]; then
        echo "Found $(echo "$alive_ips" | wc -l) responsive IP(s) in $specific"
        for ip in $alive_ips; do
            process_ip "$specific" "$ip" &
            while (( $(jobs | wc -l) >= 5 )); do sleep 1; done
        done
        wait
    else
        echo "No responsive IPs found in $specific"
    fi
fi

echo "Output files have been created in: $(realpath "$output_csv")"
echo "fping SNMP audit script completed."
