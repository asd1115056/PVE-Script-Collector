#!/bin/sh

# set -x  # Enable debug mode for troubleshooting

# Configuration
TARGET="8.8.8.8"          # Target IP for connectivity check
VM_NAME="$1"              # VM name, passed as the first argument
PACKET_LOSS_THRESHOLD="${2:-40}"  # Threshold for packet loss percentage to trigger a restart, default to 40 if not provided
SLEEP_INTERVAL="${3:-30}"          # Delay (in seconds) before restarting the VM, default to 5 if not provided

# Ensure VM name is provided
if [ -z "$VM_NAME" ]; then
    echo "Error: VM name is required."
    exit 1
fi

# Retrieve VM ID based on VM name
VM_ID=$(qm list | grep -w "$VM_NAME" | awk '{print $1}' | head -n 1)

# Exit if the VM is not found
if [ -z "$VM_ID" ]; then
    echo "Error: VM '$VM_NAME' not found!"
    qm list  # Show all VMs for debugging
    exit 1
fi

echo "Checking network for VM '$VM_NAME' (ID: $VM_ID)..."

# Perform a ping test and extract the packet loss percentage
PING_OUTPUT=$(ping -c 10 -W 1 "$TARGET")
PACKET_LOSS=$(echo "$PING_OUTPUT" | grep -oP '\d+(?=% packet loss)')

# Ensure PACKET_LOSS is not empty (to handle unexpected output)
if [ -z "$PACKET_LOSS" ]; then
    echo "Error: Unable to determine packet loss from ping output."
    exit 1
fi

echo "Packet loss: ${PACKET_LOSS}%"

# Restart VM if packet loss exceeds the threshold
if [ "$PACKET_LOSS" -ge "$PACKET_LOSS_THRESHOLD" ]; then
    echo "High packet loss detected ($PACKET_LOSS%)! Restarting VM '$VM_NAME' (ID: $VM_ID)..."

    if qm stop "$VM_ID"; then
        sleep "$SLEEP_INTERVAL"
        if qm start "$VM_ID"; then
            echo "VM '$VM_NAME' restarted successfully."
        else
            echo "Error: Failed to start VM '$VM_NAME'."
        fi
    else
        echo "Error: Failed to stop VM '$VM_NAME'."
    fi
else
    echo "Network is OK. No restart needed."
fi
