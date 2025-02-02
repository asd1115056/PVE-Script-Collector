#!/bin/sh

set -x

# Configuration
TARGET="8.8.8.8"          # Target IP to check connectivity
VM_NAME="$1"              # VM name to monitor
TIMEOUT_THRESHOLD=5       # Number of failed checks before restarting


# Exit if VM_NAME is empty
if [ -z "$VM_NAME" ]; then
    echo "Error: VM name is required."
    exit 1
fi

# Get VM ID based on VM name
VM_ID=$(qm list | grep -w "$VM_NAME" | awk '{print $1}')

# Exit if VM is not found
if [ -z "$VM_ID" ]; then
    logger -t vm_network_check "Error: VM '$VM_NAME' not found!"
    exit 1
fi

logger -t vm_network_check "Checking network for VM '$VM_NAME' (ID: $VM_ID)..."

# Ping test
if ! ping -c 5 -W 2 "$TARGET" > /dev/null 2>&1; then
    logger -t vm_network_check "Network check failed! Counting timeouts..."
    
    # Count recent failures from system logs
    TIMEOUT_COUNT=$(journalctl -t vm_network_check --since "10 minutes ago" | grep -c "Network check failed")

    if [ "$TIMEOUT_COUNT" -ge "$TIMEOUT_THRESHOLD" ]; then
        logger -t vm_network_check "Timeout exceeded $TIMEOUT_THRESHOLD times! Restarting VM '$VM_NAME' (ID: $VM_ID)..."
        
        if qm stop "$VM_ID"; then
            sleep 5
            if qm start "$VM_ID"; then
                logger -t vm_network_check "VM '$VM_NAME' restarted successfully."
            else
                logger -t vm_network_check "Error: Failed to start VM '$VM_NAME'."
            fi
        else
            logger -t vm_network_check "Error: Failed to stop VM '$VM_NAME'."
        fi
    fi
else
    logger -t vm_network_check "Network is OK."
fi
