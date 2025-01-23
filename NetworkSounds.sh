#!/bin/bash

# Check for required commands
if ! command -v ifstat &> /dev/null; then
    echo "Error: ifstat is not installed. Please install it and try again."
    exit 1
fi

if ! command -v aplay &> /dev/null; then
    echo "Error: aplay is not installed. Please install it and try again."
    exit 1
fi

# Load .env file
set -a
source ./.env
set -a

# Function to play sound
play_sound() {
    local sound_file="$SOUND_LOCATION/$1"
    aplay "$sound_file" &
}

# Function to get network statistics
get_network_stats() {
    ifstat -i "$PRIMARY_ADAPTER" 1 1 | awk 'NR==3 {print $1}'
}

# Define the maximum bandwidth in bytes (example: 1 Gbps)
MAX_BANDWIDTH_BYTES=$((125000000))

# Determine the network adapter to use
PRIMARY_ADAPTER=${OVERRIDE_ADAPTER:-$(ip route | grep default | awk '{print $5}')}

# Display the network adapter being used
echo "Using network adapter: $PRIMARY_ADAPTER"

# Initialize previous received bytes
previous_received_bytes=$(get_network_stats)

# Main loop to monitor network traffic and play sound based on conditions
while true; do
    sleep 10

    current_received_bytes=$(get_network_stats)
    received_bytes_difference=$((current_received_bytes - previous_received_bytes))
    percentage_used=$(echo "scale=2; ($received_bytes_difference / $MAX_BANDWIDTH_BYTES) * 100" | bc)

    # Update previous received bytes
    previous_received_bytes=$current_received_bytes

    # Debugging output
    echo "Received bytes difference: $received_bytes_difference"
    echo "Max bandwidth bytes: $MAX_BANDWIDTH_BYTES"
    echo "Bandwidth usage percentage: $percentage_used"

    if (( $(echo "$percentage_used >= 99" | bc -l) )); then
        play_sound "$SOUND_100"
    fi
    if (( $(echo "$percentage_used >= 90" | bc -l) )); then
        play_sound "$SOUND_90"
    fi
    if (( $(echo "$percentage_used >= 80" | bc -l) )); then
        play_sound "$SOUND_80"
    fi
    if (( $(echo "$percentage_used >= 70" | bc -l) )); then
        play_sound "$SOUND_70"
    fi
    if (( $(echo "$percentage_used >= 60" | bc -l) )); then
        play_sound "$SOUND_60"
    fi
    if (( $(echo "$percentage_used >= 50" | bc -l) )); then
        play_sound "$SOUND_50"
    fi
    if (( $(echo "$percentage_used >= 40" | bc -l) )); then
        play_sound "$SOUND_40"
    fi
    if (( $(echo "$percentage_used >= 30" | bc -l) )); then
        play_sound "$SOUND_30"
    fi
    if (( $(echo "$percentage_used >= 20" | bc -l) )); then
        play_sound "$SOUND_20"
    fi
    play_sound "$SOUND_BASE"
done