#!/bin/bash
#################################################################
# PRbL Disk Health Monitor Aliases
#################################################################

# Use PRbL detection to locate disk health script
DISK_HEALTH_CMD=""

# First try to find PRbL path from environment variables
if [ ! -z "$prbl_functions" ] && [ -f "$prbl_functions" ]; then
    # Extract PRbL path from functions path
    PRBL_PATH="${prbl_functions%/*}"
    if [ -f "$PRBL_PATH/extras/disk-health-monitor.sh" ]; then
        DISK_HEALTH_CMD="$PRBL_PATH/extras/disk-health-monitor.sh"
    fi
elif [ ! -z "$prbl_version" ]; then
    # Check common locations if prbl_version is set (during installation)
    if [ -f "$HOME/.local/share/prbl/extras/disk-health-monitor.sh" ]; then
        DISK_HEALTH_CMD="$HOME/.local/share/prbl/extras/disk-health-monitor.sh"
    elif [ -f "/usr/share/prbl/extras/disk-health-monitor.sh" ]; then
        DISK_HEALTH_CMD="/usr/share/prbl/extras/disk-health-monitor.sh"
    fi
fi

# If still not found, try standard locations
if [ -z "$DISK_HEALTH_CMD" ]; then
    # Check potential installation locations in order of preference
    if [ -f "$HOME/.local/bin/disk-health-monitor.sh" ]; then
        DISK_HEALTH_CMD="$HOME/.local/bin/disk-health-monitor.sh"
    elif [ -f "$HOME/.local/share/prbl/extras/disk-health-monitor.sh" ]; then
        DISK_HEALTH_CMD="$HOME/.local/share/prbl/extras/disk-health-monitor.sh"
    elif [ -f "/usr/share/prbl/extras/disk-health-monitor.sh" ]; then
        DISK_HEALTH_CMD="/usr/share/prbl/extras/disk-health-monitor.sh"
    elif [ -f "$HOME/.local/share/prbl/disk_health/disk-health-monitor.sh" ]; then
        DISK_HEALTH_CMD="$HOME/.local/share/prbl/disk_health/disk-health-monitor.sh"
    elif [ -f "/usr/local/bin/disk-health-monitor.sh" ]; then
        DISK_HEALTH_CMD="/usr/local/bin/disk-health-monitor.sh"
    fi
fi

# Only create aliases if the script is found
if [ -f "$DISK_HEALTH_CMD" ]; then
    # Make sure the script is executable
    chmod +x "$DISK_HEALTH_CMD" 2>/dev/null

    # Aliases for disk health monitoring
    alias disk-check="$DISK_HEALTH_CMD -c"                # Run a manual disk health check
    alias disk-status="$DISK_HEALTH_CMD -s"               # Display disk health summary
    alias disk-detail="$DISK_HEALTH_CMD -d"               # Display detailed disk info
    alias disk-alert="$DISK_HEALTH_CMD -a"                # Set alert method
    alias disk-blink="$DISK_HEALTH_CMD -b"                # Make disk LED blink
    
    # Functions for more advanced usage
    # View disk history over time (past 7 days)
    disk-history() {
        local days=${1:-7}
        local disk_health_dir="$HOME/.local/share/prbl/disk_health"
        local history_dir="$disk_health_dir/history"
        
        echo "Disk health history for the past $days days:"
        echo "-------------------------------------------"
        
        # Get list of history files, sorted by date
        local history_files=$(find "$history_dir" -name "*.json" -type f -mtime -$days | sort)
        
        if [ -z "$history_files" ]; then
            echo "No history found for the past $days days."
            return
        fi
        
        # Process each history file
        for file in $history_files; do
            local date=$(basename "$file" .json)
            local year=${date:0:4}
            local month=${date:4:2}
            local day=${date:6:2}
            
            echo "Date: $year-$month-$day"
            
            # Extract disk status summary for each disk
            if command -v jq >/dev/null 2>&1; then
                jq -r '.[-1].disks | to_entries[] | "\(.key): \(.value.status) (\(.value.health_score)/100)"' "$file" | 
                while read line; do
                    disk=$(echo "$line" | cut -d':' -f1)
                    status=$(echo "$line" | cut -d':' -f2- | cut -d'(' -f1 | xargs)
                    score=$(echo "$line" | grep -o '([0-9]*/100)' | tr -d '()' | cut -d'/' -f1)
                    
                    # Colorize output
                    if [ "$status" = "healthy" ]; then
                        echo -e "  /dev/$disk: \033[32m$status\033[0m (Score: $score/100)"
                    elif [ "$status" = "warning" ]; then
                        echo -e "  /dev/$disk: \033[33m$status\033[0m (Score: $score/100)"
                    elif [ "$status" = "critical" ]; then
                        echo -e "  /dev/$disk: \033[31m$status\033[0m (Score: $score/100)"
                    else
                        echo -e "  /dev/$disk: $status (Score: $score/100)"
                    fi
                done
            else
                echo "  Install jq for detailed history parsing"
            fi
            echo "-------------------------------------------"
        done
    }
    
    # Compare health score of a specific disk over time
    disk-trend() {
        local disk="$1"
        local days=${2:-30}
        local disk_health_dir="$HOME/.local/share/prbl/disk_health"
        local history_dir="$disk_health_dir/history"
        
        if [ -z "$disk" ]; then
            echo "Usage: disk-trend <disk> [days]"
            echo "Example: disk-trend sda 30"
            return 1
        fi
        
        echo "Health trend for /dev/$disk over the past $days days:"
        echo "-------------------------------------------"
        
        # Get list of history files, sorted by date
        local history_files=$(find "$history_dir" -name "*.json" -type f -mtime -$days | sort)
        
        if [ -z "$history_files" ]; then
            echo "No history found for the past $days days."
            return
        fi
        
        # Check if jq is available
        if ! command -v jq >/dev/null 2>&1; then
            echo "jq is required for this function. Please install jq."
            return 1
        fi
        
        # Process each history file
        for file in $history_files; do
            local date=$(basename "$file" .json)
            local year=${date:0:4}
            local month=${date:4:2}
            local day=${date:6:2}
            
            # Extract health score for the specified disk
            local score=$(jq -r ".[-1].disks[\"$disk\"].health_score" "$file" 2>/dev/null)
            local temp=$(jq -r ".[-1].disks[\"$disk\"].temperature" "$file" 2>/dev/null)
            
            # Skip if disk wasn't found in this record
            if [ "$score" = "null" ] || [ -z "$score" ]; then
                continue
            fi
            
            # Generate a simple bar graph using score value
            local bar=""
            local bar_length=$((score / 5)) # 20 characters for 100%
            for ((i=0; i<bar_length; i++)); do
                bar+="#"
            done
            
            # Colorize based on score
            local color=""
            if [ "$score" -ge 80 ]; then
                color="\033[32m" # green
            elif [ "$score" -ge 60 ]; then
                color="\033[33m" # yellow
            else
                color="\033[31m" # red
            fi
            
            temp_str=""
            if [ "$temp" != "null" ] && [ ! -z "$temp" ]; then
                temp_str=" | Temp: ${temp}°C"
            fi
            
            printf "$year-$month-$day: ${color}%-20s\033[0m Score: %d/100%s\n" "$bar" "$score" "$temp_str"
        done
    }
    
    # Show available alert methods
    disk-alert-help() {
        echo "Available alert methods:"
        echo "  console         - Display alerts on the console"
        echo "  email           - Send alerts via email (will prompt for email address)"
        echo "  custom_command  - Run a custom command (will prompt for command)"
        echo ""
        echo "Usage:"
        echo "  disk-alert console"
        echo "  disk-alert email"
        echo "  disk-alert custom_command"
    }
fi