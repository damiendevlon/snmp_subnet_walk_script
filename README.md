README: SNMP Subnet Walker Script

Overview

`SNMP_Subnet_walker.sh` is a script designed to perform SNMP walks across IP subnets, identifying network devices by retrieving essential system 
information like description, object ID, contact, name, and location. This information is pulled based on provided SNMP community strings.

Directory Structure

Place all files in `/root/GIT/snmp_subnet_walk_script/`:
- SNMP_Subnet_walker.sh: Main script to run the SNMP walk.
- community_strings.txt: File containing SNMP community strings, one per line.
- community_strings_updater.sh: Script for adding or updating SNMP community strings in `community_strings.txt`.

Credits & Purpose
This script was developed with assistance from OpenAI, who did a wonderful job helping me build and test it on my personal home network. While I still can’t get my mesh wireless (Aruba APs) to respond, everything else works as expected
Requirements

1. SNMP Tools: Ensure `snmpget`, `snmpwalk`, and `fping` are installed. To install on Debian/Ubuntu:
   sudo apt-get update
   sudo apt-get install snmp snmp-mibs-downloader fping

2. Permissions: Make sure the scripts are executable:
   chmod +x SNMP_Subnet_walker.sh community_strings_updater.sh

Input File Structure

1. Input CSV File (Optional for bulk mode): Include a CSV file to scan multiple subnets. The first column should be `Network - Specific`.

2. File Format Example:
   Network - Specific,Network - Supernet,Description
   192.168.1.0/30,192.168.0.0/16,Test Network

How to Run the Script

1. Single Subnet Mode (no CSV file required):
   ./SNMP_Subnet_walker.sh
   - When prompted, enter a subnet in CIDR format (e.g., `192.168.1.0/24`).

2. Bulk Mode (with CSV file):
   ./SNMP_Subnet_walker.sh <filename.csv>
   - Replace `<filename.csv>` with the path to your input CSV file.

Output

The script outputs a CSV file with SNMP information. If using bulk mode, it creates a folder in the same directory named after the CSV file 
(without the extension), followed by a subfolder with the current date. Example output structure:

SingleSubnetAudit/
├── 102724_192.168.1.0_24.csv
SNMP_Subnet_walk_script/
├── updated_test_networks.csv

Each output file has the following headers:
Network - Specific,IP Address,Community String,sysDescr,sysContact,sysObjectID,sysLocation,sysName

Updating Community Strings

Run `community_strings_updater.sh` to manage community strings.

1. To View or Add Community Strings:
   ./community_strings_updater.sh
   - Follow prompts to view, add, or overwrite community strings in `community_strings.txt`.

Troubleshooting

- Community File Not Found: Ensure `community_strings.txt` exists.
- Empty Output: Confirm that SNMP is configured on the devices and the IP addresses are reachable.
- Invalid Input: For single subnet mode, ensure the subnet is in CIDR format (e.g., `192.168.1.0/24`).

Example Commands

- Single subnet:
  ./SNMP_Subnet_walker.sh
- Bulk mode with a CSV file:
  ./SNMP_Subnet_walker.sh test_networks.csv

