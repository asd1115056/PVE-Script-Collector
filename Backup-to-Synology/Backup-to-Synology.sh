#!/bin/bash

# Input Values
SERVER_MAC="$1"

# Default values
SCAN_RANGE="192.168.200.0/24"
MAX_RETRIES=12
INTERVAL=10
SERVER_IP=""

wake_on_lan() {
    local target_ip="255.255.255.255"
    local target_port="9"
    local magic_packet
    local target_mac

    target_mac=$(echo $1 | sed 's/[ :-]//g')

    # Check whether the MAC is 12 codes (6 Bytes)
    [ ${#target_mac} -ne 12 ] && return 1

    # A magic packet consists of 12 bytes of FF followed by 16 repetitions of the target's MAC address.
    magic_packet=$(printf "f%.0s" {1..12}; printf "$target_mac%.0s" {1..16})

    # Hex-escape
    magic_packet=$(echo $magic_packet | sed -e 's/../\\x&/g')

    echo -ne "$magic_packet" | nc -w1 -u -b "$target_ip" "$target_port" 2>/dev/null
    echo "Sent magic packet to $target_mac at $target_ip:$target_port"
}

# Used to check if the device is up and responding to pings
check_device_online() {
    local retries=0
    local retry_count=0
    while [ "$retries" -lt "$MAX_RETRIES" ]; do
        echo "Scanning network for MAC: $SERVER_MAC (Attempt $((retries+1))/$MAX_RETRIES)"
        
        found_ip=$(nmap -sn "$SCAN_RANGE" -T5 --host-timeout 200ms --min-parallelism 10 | \
            awk "/^Nmap scan report for/{host=\$0} /MAC Address: $SERVER_MAC/{split(host, a, \" \"); print a[6]}" | \
            sed 's/[()]//g')
        
        if [ -n "$found_ip" ]; then
            SERVER_IP=$found_ip
            echo "Device found at IP: $SERVER_IP"
            return 0
        fi

        # Wait for the specified interval after spark check
        ((retry_count++))
        sleep "$INTERVAL"
        retries=$((retries+1))
    done

    # If the maximum number of views is exceeded, it is considered a failure.
    echo "Error: Device startup failed, maximum number of checks $MAX_RETRIES exceeded"
    return 1
}

power_on() {
    echo "Starting power on sequence for device with MAC: $SERVER_MAC"
    start_time=$(date +%s)
    wake_on_lan "$SERVER_MAC"

    # Check if the device is online
    if check_device_online; then
        end_time=$(date +%s)
        elapsed_time=$((end_time - start_time))
        echo "Power on sequence completed successfully in $elapsed_time seconds"
        return 0 # Success
    else
        echo "Power on sequence failed."
        return 1 # Failure
    fi
}

power_on "$SERVER_MAC"
