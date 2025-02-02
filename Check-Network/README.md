# Check Network Script

## Overview

On my PVE machine, I passed through the I226-V (Rev 04) Network Interface Card to OpenWrt as the WAN port. However, it sometimes becomes unstable for no apparent reason.

To fix this issue, I need to reboot the OpenWrt VM multiple times. But since the WAN connection is unstable, restarting the VM via SSH or the web management page can be difficult.

To address this, the `Check_Network.sh` script is designed to monitor the network connectivity of a specified virtual machine (VM) by pinging a target IP address. If the network check fails multiple times within a defined threshold, the script will automatically restart the VM to restore connectivity.


## Features

- **Target IP**: The script pings a predefined target IP address (default is `8.8.8.8`).
- **VM Monitoring**: It takes the VM name as an argument and checks its network status.
- **Failure Threshold**: If the network check fails a specified number of times, the script will restart the VM.
- **Logging**: It logs the network check results and any actions taken to the system logger.

## Usage

To use the script, run the following command:

```bash
./Check_Network.sh <VM_NAME>
```

Replace `<VM_NAME>` with the name of the virtual machine you want to monitor.

## Scheduled Execution

To run the script at regular intervals, you can use `cron`. Here's how to set it up:
1. Copy the script to `/bin` and set the execution permission:
    ```bash
    chmod +x Check_Network.sh
    ```
2. Open the crontab editor:
    ```bash
    crontab -e
    ```

3. Add a line to schedule the script. For example, to run the script every 5 minutes, add:
    ```bash
    SHELL=/bin/sh
    PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
    
    */5 * * * * Check_Network.sh <VM_NAME>
    ```

    Replace `<VM_NAME>` with the name of the virtual machine.

4. Save and exit the editor.

