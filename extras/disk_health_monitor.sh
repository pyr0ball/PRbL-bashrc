# Function to control disk LEDs using ledctl/sg_ses/smartctl/hdparm
disk_led_control() {
    local disk="$1"
    local action="$2"
    local disk_path="/dev/$disk"
    local success=false
    
    log "Attempting to $action LED for $disk_path"
    
    # Try ledctl if available (for SAS/SCSI disks with enclosure management)
    if command -v ledctl &> /dev/null; then
        log "Using ledctl..."
        case "$action" in
            "on"|"solid")
                sudo ledctl locate="$disk_path"
                success=$?
                ;;
            "blink"|"flash")
                sudo ledctl locate_on="$disk_path"
                success=$?
                ;;
            "off")
                sudo ledctl locate_off="$disk_path"
                success=$?
                ;;
        esac
    fi
    
    # If ledctl didn't work, try sg_ses (for SAS enclosures)
    if [ "$success" != "0" ] && command -v sg_ses &> /dev/null; then
        log "Using sg_ses..."
        # Find enclosure device
        local enclosure
        for enc in /dev/sg*; do
            if sg_ses --page=status "$enc" 2>/dev/null | grep -q "Enclosure Status"; then
                enclosure="$enc"
                break
            fi
        done
        
        if [ -n "$enclosure" ]; then
            # Get slot number for this drive
            local slot
            slot=$(sg_map -i | grep -i "$disk" | awk '{print $1}' | head -1)
            
            if [ -n "$slot" ]; then
                case "$action" in
                    "on"|"solid")
                        sudo sg_ses --index="$slot" --set=ident "$enclosure"
                        success=$?
                        ;;
                    "blink"|"flash")
                        sudo sg_ses --index="$slot" --set=ident "$enclosure"
                        success=$?
                        ;;
                    "off")
                        sudo sg_ses --index="$slot" --clear=ident "$enclosure"
                        success=$?
                        ;;
                esac
            fi
        fi
    fi
    
    # Try smartctl (for SATA/NVMe disks that support it)
    if [ "$success" != "0" ] && command -v smartctl &> /dev/null; then
        log "Using smartctl..."
        case "$action" in
            "on"|"solid")
                sudo smartctl -s on -d sat "$disk_path" >/dev/null 2>&1
                sudo smartctl --set=standby,now "$disk_path" >/dev/null 2>&1
                success=$?
                ;;
            "blink"|"flash")
                sudo smartctl -s on -d sat "$disk_path" >/dev/null 2>&1
                success=$?
                ;;
            "off")
                sudo smartctl -s off -d sat "$disk_path" >/dev/null 2>&1
                success=$?
                ;;
        esac
    fi
    
    # Try hdparm as a last resort (for ATA IDLE/STANDBY control)
    if [ "$success" != "0" ] && command -v hdparm &> /dev/null; then
        log "Using hdparm..."
        case "$action" in
            "on"|"solid")
                sudo hdparm -S 0 "$disk_path" >/dev/null 2>&1  # Disable standby timeout
                sudo hdparm -Y "$disk_path" >/dev/null 2>&1    # Force standby mode
                success=$?
                ;;
            "blink"|"flash")
                # No direct blink option with hdparm, cycle power state
                sudo hdparm -y "$disk_path" >/dev/null 2>&1    # Put in standby
                sleep 1
                sudo hdparm -C "$disk_path" >/dev/null 2>&1    # Get status (wakes drive)
                success=$?
                ;;
            "off")
                sudo hdparm -S 0 "$disk_path" >/dev/null 2>&1  # Disable standby timeout
                sudo hdparm -C "$disk_path" >/dev/null 2>&1    # Get status (wakes drive)
                success=$?
                ;;
        esac
    fi
    
    if [ "$success" = "0" ]; then
        log "Successfully set $disk_path LED to $action"
        return 0
    else
        log "Failed to control LED for $disk_path"
        return 1
    fi
}

# Function to run various disk tests
run_disk_test() {
    local disk="$1"
    local test_type="$2"
    local disk_path="/dev/$disk"
    
    log "Running $test_type test on $disk_path"
    
    case "$test_type" in
        "short")
            sudo smartctl -t short "$disk_path"
            log "Short self-test started on $disk_path. This will take ~2 minutes."
            ;;
        "long")
            sudo smartctl -t long "$disk_path"
            log "Long self-test started on $disk_path. This can take several hours."
            ;;
        "conveyance")
            sudo smartctl -t conveyance "$disk_path"
            log "Conveyance self-test started on $disk_path. This will take ~5 minutes."
            ;;
        "offline")
            sudo smartctl -t offline "$disk_path"
            log "Offline self-test started on $disk_path. This will run in the background."
            ;;
        "status")
            sudo smartctl -c "$disk_path"
            ;;
        "abort")
            sudo smartctl -X "$disk_path"
            log "Aborted any running tests on $disk_path"
            ;;
        *)
            log "Unknown test type: $test_type"
            return 1
            ;;
    esac
    
    return 0
}

# Interactive menu mode for disk management
interactive_mode() {
    if [[ $PRBL_AVAILABLE != true ]]; then
        echo "PRbL functions are required for interactive mode."
        echo "Please install PRbL-bashrc or run in non-interactive mode."
        exit 1
    fi
    
    set-boxtype "double"
    
    # Get list of disks
    readarray -t all_disks < <(lsblk -d -o NAME,SIZE,MODEL,TYPE | grep -v "loop\|sr0\|NAME" | sort)
    
    while true; do
        # Main menu
        clear
        boxtop
        center "${bld}${grn}Disk Health Management System${dfl}"
        boxbottom
        
        boxtop
        center "${bld}Available Disks${dfl}"
        boxseparator
        
        # Display disk list with status
        for i in "${!all_disks[@]}"; do
            disk_info="${all_disks[$i]}"
            disk_name=$(echo "$disk_info" | awk '{print $1}')
            disk_size=$(echo "$disk_info" | awk '{print $2}')
            disk_model=$(echo "$disk_info" | awk '{$1=""; $2=""; print $0}' | xargs)
            
            # Get current status from database if available
            if [ -f "$HISTORY_DB" ]; then
                health=$(sqlite3 "$HISTORY_DB" "SELECT health_percentage FROM disks WHERE device='$disk_name' ORDER BY date DESC LIMIT 1;")
                status=$(sqlite3 "$HISTORY_DB" "SELECT smart_status FROM disks WHERE device='$disk_name' ORDER BY date DESC LIMIT 1;")
                
                if [ -n "$health" ]; then
                    if [ "$health" -gt 80 ]; then
                        health_color="${grn}"
                    elif [ "$health" -gt 50 ]; then
                        health_color="${ylw}"
                    else
                        health_color="${lrd}"
                    fi
                    
                    status_str="${health_color}${health}%${dfl}"
                    if [ -n "$status" ]; then
                        status_str+=" (${status})"
                    fi
                else
                    status_str="Unknown"
                fi
            else
                status_str="Not scanned"
            fi
            
            boxline "$((i+1)). ${bld}${disk_name}${dfl} - ${blu}${disk_size}${dfl} - ${disk_model} - ${status_str}"
        done
        
        boxseparator
        boxline "A. Scan all disks"
        boxline "B. LED control menu"
        boxline "C. SMART test menu"
        boxline "Q. Return to main menu"
        boxbottom
        
        read -p "Enter your choice: " choice
        
        case "$choice" in
            [0-9]*)
                if [ "$choice" -ge 1 ] && [ "$choice" -le "${#all_disks[@]}" ]; then
                    selected_disk=$(echo "${all_disks[$((choice-1))]}" | awk '{print $1}')
                    disk_menu "$selected_disk"
                else
                    log "Invalid option. Please try again."
                    sleep 2
                fi
                ;;
            [Aa])
                # Scan all disks
                boxtop
                center "${bld}Scanning all disks...${dfl}"
                boxbottom
                
                for disk_info in "${all_disks[@]}"; do
                    disk_name=$(echo "$disk_info" | awk '{print $1}')
                    get_smart_data "$disk_name"
                done
                
                boxtop
                center "${bld}${grn}Scan complete!${dfl}"
                boxbottom
                read -p "Press Enter to continue..."
                ;;
            [Bb])
                led_control_menu
                ;;
            [Cc])
                smart_test_menu
                ;;
            [Qq])
                return
                ;;
            *)
                log "Invalid option. Please try again."
                sleep 2
                ;;
        esac
    done
}

# Menu for individual disk options
disk_menu() {
    local disk="$1"
    
    while true; do
        clear
        boxtop
        center "${bld}Disk Management: ${blu}/dev/$disk${dfl}"
        boxbottom
        
        # Get disk details
        if [ -f "$HISTORY_DB" ]; then
            local query=$(sqlite3 -header -column "$HISTORY_DB" "SELECT model, serial, capacity, temperature, power_on_hours/24 as power_on_days, health_percentage, smart_status FROM disks WHERE device='$disk' ORDER BY date DESC LIMIT 1;")
            boxtop
            center "${bld}Disk Details${dfl}"
            boxseparator
            if [ -n "$query" ]; then
                echo "$query" | while IFS= read -r line; do
                    boxline "$line"
                done
            else
                boxline "No data available. Please scan this disk first."
            fi
            boxbottom
        fi
        
        boxtop
        center "${bld}Options${dfl}"
        boxseparator
        boxline "1. Scan disk"
        boxline "2. Turn on LED (solid)"
        boxline "3. Blink LED"
        boxline "4. Turn off LED"
        boxline "5. Run short SMART test"
        boxline "6. Run long SMART test"
        boxline "7. Run conveyance SMART test"
        boxline "8. Check test status"
        boxline "9. Abort running tests"
        boxline "R. Return to main menu"
        boxbottom
        
        read -p "Enter your choice: " choice
        
        case "$choice" in
            1)
                boxtop
                center "${bld}Scanning $disk...${dfl}"
                boxbottom
                get_smart_data "$disk"
                boxline "Scan complete!"
                read -p "Press Enter to continue..."
                ;;
            2)
                disk_led_control "$disk" "on"
                read -p "Press Enter to continue..."
                ;;
            3)
                disk_led_control "$disk" "blink"
                read -p "Press Enter to continue..."
                ;;
            4)
                disk_led_control "$disk" "off"
                read -p "Press Enter to continue..."
                ;;
            5)
                run_disk_test "$disk" "short"
                read -p "Press Enter to continue..."
                ;;
            6)
                run_disk_test "$disk" "long"
                read -p "Press Enter to continue..."
                ;;
            7)
                run_disk_test "$disk" "conveyance"
                read -p "Press Enter to continue..."
                ;;
            8)
                boxtop
                center "${bld}SMART Test Status for $disk${dfl}"
                boxbottom
                run_disk_test "$disk" "status"
                read -p "Press Enter to continue..."
                ;;
            9)
                run_disk_test "$disk" "abort"
                read -p "Press Enter to continue..."
                ;;
            [Rr])
                return
                ;;
            *)
                log "Invalid option. Please try again."
                sleep 2
                ;;
        esac
    done
}

# LED control menu for all disks
led_control_menu() {
    while true; do
        clear
        # Get list of disks
        readarray -t led_disks < <(lsblk -d -o NAME,SIZE,MODEL | grep -v "loop\|sr0\|NAME" | sort)
        
        boxtop
        center "${bld}${grn}LED Control${dfl}"
        boxbottom
        
        boxtop
        center "${bld}Available Disks${dfl}"
        boxseparator
        
        # Display disk list
        for i in "${!led_disks[@]}"; do
            disk_info="${led_disks[$i]}"
            disk_name=$(echo "$disk_info" | awk '{print $1}')
            disk_size=$(echo "$disk_info" | awk '{print $2}')
            disk_model=$(echo "$disk_info" | awk '{$1=""; $2=""; print $0}' | xargs)
            
            boxline "$((i+1)). ${bld}${disk_name}${dfl} - ${blu}${disk_size}${dfl} - ${disk_model}"
        done
        
        boxseparator
        boxline "A. Turn on ALL LEDs"
        boxline "B. Blink ALL LEDs"
        boxline "C. Turn off ALL LEDs"
        boxline "R. Return to main menu"
        boxbottom
        
        read -p "Enter your choice [#/A/B/C/R]: " choice
        
        case "$choice" in
            [0-9]*)
                if [ "$choice" -ge 1 ] && [ "$choice" -le "${#led_disks[@]}" ]; then
                    selected_disk=$(echo "${led_disks[$((choice-1))]}" | awk '{print $1}')
                    
                    boxtop
                    center "${bld}LED Control for ${blu}/dev/$selected_disk${dfl}"
                    boxseparator
                    boxline "1. Turn on LED (solid)"
                    boxline "2. Blink LED"
                    boxline "3. Turn off LED"
                    boxline "R. Return"
                    boxbottom
                    
                    read -p "Enter your choice [1/2/3/R]: " led_choice
                    
                    case "$led_choice" in
                        1)
                            disk_led_control "$selected_disk" "on"
                            ;;
                        2)
                            disk_led_control "$selected_disk" "blink"
                            ;;
                        3)
                            disk_led_control "$selected_disk" "off"
                            ;;
                        [Rr])
                            continue
                            ;;
                        *)
                            log "Invalid option. Please try again."
                            sleep 2
                            ;;
                    esac
                    
                    read -p "Press Enter to continue..."
                    
                else
                    log "Invalid disk number. Please try again."
                    sleep 2
                fi
                ;;
            [Aa])
                boxtop
                center "${bld}Turning on all disk LEDs...${dfl}"
                boxbottom
                
                for disk_info in "${led_disks[@]}"; do
                    disk_name=$(echo "$disk_info" | awk '{print $1}')
                    disk_led_control "$disk_name" "on"
                done
                
                read -p "Press Enter to continue..."
                ;;
            [Bb])
                boxtop
                center "${bld}Blinking all disk LEDs...${dfl}"
                boxbottom
                
                for disk_info in "${led_disks[@]}"; do
                    disk_name=$(echo "$disk_info" | awk '{print $1}')
                    disk_led_control "$disk_name" "blink"
                done
                
                read -p "Press Enter to continue..."
                ;;
            [Cc])
                boxtop
                center "${bld}Turning off all disk LEDs...${dfl}"
                boxbottom
                
                for disk_info in "${led_disks[@]}"; do
                    disk_name=$(echo "$disk_info" | awk '{print $1}')
                    disk_led_control "$disk_name" "off"
                done
                
                read -p "Press Enter to continue..."
                ;;
            [Rr])
                return
                ;;
            *)
                log "Invalid option. Please try again."
                sleep 2
                ;;
        esac
    done
}

# SMART test menu for all disks
smart_test_menu() {
    while true; do
        clear
        # Get list of disks
        readarray -t test_disks < <(lsblk -d -o NAME,SIZE,MODEL | grep -v "loop\|sr0\|NAME" | sort)
        
        boxtop
        center "${bld}${grn}SMART Test Control${dfl}"
        boxbottom
        
        boxtop
        center "${bld}Available Disks${dfl}"
        boxseparator
        
        # Display disk list
        for i in "${!test_disks[@]}"; do
            disk_info="${test_disks[$i]}"
            disk_name=$(echo "$disk_info" | awk '{print $1}')
            disk_size=$(echo "$disk_info" | awk '{print $2}')
            disk_model=$(echo "$disk_info" | awk '{$1=""; $2=""; print $0}' | xargs)
            
            boxline "$((i+1)). ${bld}${disk_name}${dfl} - ${blu}${disk_size}${dfl} - ${disk_model}"
        done
        
        boxseparator
        boxline "A. Run short test on ALL disks"
        boxline "B. Check status of ALL disks"
        boxline "C. Abort tests on ALL disks"
        boxline "R. Return to main menu"
        boxbottom
        
        read -p "Enter your choice [#/A/B/C/R]: " choice
        
        case "$choice" in
            [0-9]*)
                if [ "$choice" -ge 1 ] && [ "$choice" -le "${#test_disks[@]}" ]; then
                    selected_disk=$(echo "${test_disks[$((choice-1))]}" | awk '{print $1}')
                    
                    boxtop
                    center "${bld}SMART Test for ${blu}/dev/$selected_disk${dfl}"
                    boxseparator
                    boxline "1. Run short test (~2 minutes)"
                    boxline "2. Run long test (hours)"
                    boxline "3. Run conveyance test (~5 minutes)"
                    boxline "4. Run offline test (background)"
                    boxline "5. Check test status"
                    boxline "6. Abort running tests"
                    boxline "R. Return"
                    boxbottom
                    
                    read -p "Enter your choice [1-6/R]: " test_choice
                    
                    case "$test_choice" in
                        1)
                            run_disk_test "$selected_disk" "short"
                            ;;
                        2)
                            run_disk_test "$selected_disk" "long"
                            ;;
                        3)
                            run_disk_test "$selected_disk" "conveyance"
                            ;;
                        4)
                            run_disk_test "$selected_disk" "offline"
                            ;;
                        5)
                            boxtop
                            center "${bld}SMART Test Status for $selected_disk${dfl}"
                            boxbottom
                            run_disk_test "$selected_disk" "status"
                            ;;
                        6)
                            run_disk_test "$selected_disk" "abort"
                            ;;
                        [Rr])
                            continue
                            ;;
                        *)
                            log "Invalid option. Please try again."
                            sleep 2
                            ;;
                    esac
                    
                    read -p "Press Enter to continue..."
                    
                else
                    log "Invalid disk number. Please try again."
                    sleep 2
                fi
                ;;
            [Aa])
                boxtop
                center "${bld}Running short tests on all disks...${dfl}"
                boxbottom
                
                for disk_info in "${test_disks[@]}"; do
                    disk_name=$(echo "$disk_info" | awk '{print $1}')
                    run_disk_test "$disk_name" "short"
                done
                
                boxline "Tests have been initiated on all disks."
                boxline "Use 'Check status' option to monitor progress."
                read -p "Press Enter to continue..."
                ;;
            [Bb])
                boxtop
                center "${bld}Checking SMART test status on all disks...${dfl}"
                boxbottom
                
                for disk_info in "${test_disks[@]}"; do
                    disk_name=$(echo "$disk_info" | awk '{print $1}')
                    boxline "${bld}${blu}Disk /dev/$disk_name:${dfl}"
                    run_disk_test "$disk_name" "status"
                    echo
                done
                
                read -p "Press Enter to continue..."
                ;;
            [Cc])
                boxtop
                center "${bld}Aborting tests on all disks...${dfl}"
                boxbottom
                
                for disk_info in "${test_disks[@]}"; do
                    disk_name=$(echo "$disk_info" | awk '{print $1}')
                    run_disk_test "$disk_name" "abort"
                done
                
                read -p "Press Enter to continue..."
                ;;
            [Rr])
                return
                ;;
            *)
                log "Invalid option. Please try again."
                sleep 2
                ;;
        esac
    done
}#!/bin/bash
# Disk Health Monitoring System
# Purpose: Monitor SMART status of disks, mdadm arrays, and track health over time
# Author: Claude
# Date: 2025-04-09
# Usage: Set up as a systemd service or run manually

# Configuration
LOG_DIR="/var/log/disk-health"
HISTORY_DB="/var/lib/disk-health/history.db"
CONFIG_FILE="/etc/disk-health/config.json"
ALERT_THRESHOLD=20  # Default percentage of lifetime/health remaining to trigger alert
HOSTNAME=$(hostname)
EMAIL_RECIPIENT="admin@example.com"  # Default email

# PRbL integration - Check if PRbL functions are available
if type -t boxline >/dev/null; then
    PRBL_AVAILABLE=true
else
    PRBL_AVAILABLE=false
fi

# Fallback log function if PRbL isn't available
log() {
    local message="$1"
    local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    local log_message="[$timestamp] $message"
    
    # Write to log file
    echo "$log_message" >> "$LOG_DIR/disk-health.log"
    
    # Output to console
    if [[ $PRBL_AVAILABLE == true ]]; then
        boxline "$message"
    else
        echo "$log_message"
    fi
}

# Ensure directories exist
mkdir -p "$LOG_DIR" /var/lib/disk-health /etc/disk-health

# Create config file if it doesn't exist
if [ ! -f "$CONFIG_FILE" ]; then
    cat > "$CONFIG_FILE" << EOF
{
    "email_alerts": true,
    "signal_alerts": false,
    "telegram_alerts": false,
    "alert_threshold": $ALERT_THRESHOLD,
    "email_recipient": "$EMAIL_RECIPIENT",
    "signal_number": "",
    "telegram_bot_token": "",
    "telegram_chat_id": "",
    "check_interval_days": 1,
    "history_retention_days": 365,
    "ignore_disks": []
}
EOF
    log "Created default configuration at $CONFIG_FILE"
fi

# Initialize SQLite database if it doesn't exist
if [ ! -f "$HISTORY_DB" ]; then
    sqlite3 "$HISTORY_DB" << EOF
CREATE TABLE disks (
    date TEXT,
    hostname TEXT,
    device TEXT,
    model TEXT,
    serial TEXT,
    capacity TEXT,
    temperature INTEGER,
    power_on_hours INTEGER,
    health_percentage INTEGER,
    pending_sectors INTEGER,
    reallocated_sectors INTEGER,
    crc_errors INTEGER,
    smart_status TEXT,
    PRIMARY KEY (date, hostname, device)
);

CREATE TABLE arrays (
    date TEXT,
    hostname TEXT,
    array_name TEXT,
    level TEXT,
    devices TEXT,
    status TEXT,
    used_percent INTEGER,
    PRIMARY KEY (date, hostname, array_name)
);

CREATE TABLE controller_info (
    date TEXT,
    hostname TEXT,
    controller_type TEXT,
    model TEXT,
    status TEXT,
    temperature INTEGER,
    PRIMARY KEY (date, hostname, controller_type, model)
);
EOF
    log "Initialized database at $HISTORY_DB"
fi

# Load configuration
if [ -f "$CONFIG_FILE" ]; then
    EMAIL_RECIPIENT=$(jq -r '.email_recipient' "$CONFIG_FILE")
    ALERT_THRESHOLD=$(jq -r '.alert_threshold' "$CONFIG_FILE")
    EMAIL_ALERTS=$(jq -r '.email_alerts' "$CONFIG_FILE")
    SIGNAL_ALERTS=$(jq -r '.signal_alerts' "$CONFIG_FILE")
    SIGNAL_NUMBER=$(jq -r '.signal_number' "$CONFIG_FILE")
    TELEGRAM_ALERTS=$(jq -r '.telegram_alerts' "$CONFIG_FILE")
    TELEGRAM_BOT_TOKEN=$(jq -r '.telegram_bot_token' "$CONFIG_FILE")
    TELEGRAM_CHAT_ID=$(jq -r '.telegram_chat_id' "$CONFIG_FILE")
    IGNORE_DISKS=$(jq -r '.ignore_disks | join(" ")' "$CONFIG_FILE")
fi

# Function to send alerts
send_alert() {
    local subject="$1"
    local message="$2"
    local date_str=$(date +"%Y-%m-%d %H:%M:%S")
    
    # Log the alert
    log "ALERT: $subject - $message"
    
    # Email alert
    if [ "$EMAIL_ALERTS" = "true" ]; then
        echo -e "Subject: [DISK-HEALTH] $subject\n\n$date_str\nHost: $HOSTNAME\n\n$message" | sendmail "$EMAIL_RECIPIENT"
        log "Email alert sent to $EMAIL_RECIPIENT"
    fi
    
    # Signal alert
    if [ "$SIGNAL_ALERTS" = "true" ] && [ -n "$SIGNAL_NUMBER" ]; then
        # Check if signal-cli is installed
        if command -v signal-cli &> /dev/null; then
            signal-cli -u "$SIGNAL_NUMBER" send -m "[DISK-HEALTH] $subject - $message" "$SIGNAL_NUMBER"
            log "Signal alert sent to $SIGNAL_NUMBER"
        else
            log "ERROR: signal-cli not installed. Cannot send Signal alerts."
        fi
    fi
    
    # Telegram alert
    if [ "$TELEGRAM_ALERTS" = "true" ] && [ -n "$TELEGRAM_BOT_TOKEN" ] && [ -n "$TELEGRAM_CHAT_ID" ]; then
        curl -s -X POST "https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendMessage" \
            -d chat_id="$TELEGRAM_CHAT_ID" \
            -d text="[DISK-HEALTH] $subject%0A%0A$message" \
            -d parse_mode="HTML" > /dev/null
        log "Telegram alert sent to chat $TELEGRAM_CHAT_ID"
    fi
}

# Function to get SMART data for a disk
get_smart_data() {
    local disk="$1"
    local today=$(date +"%Y-%m-%d")
    local smart_info
    local model
    local serial
    local capacity
    local temp
    local power_on_hours
    local health
    local pending_sectors
    local reallocated_sectors
    local crc_errors
    local smart_status
    
    # Skip if disk is in ignore list
    for ignored in $IGNORE_DISKS; do
        if [ "$disk" = "$ignored" ]; then
            log "Skipping ignored disk $disk"
            return
        fi
    done
    
    # Check if smartctl is installed
    if ! command -v smartctl &> /dev/null; then
        log "ERROR: smartctl not installed. Cannot get SMART data."
        send_alert "SMART Tool Missing" "smartctl is not installed on $HOSTNAME. Please install smartmontools package."
        return
    fi

    # Check if disk exists
    if [ ! -b "/dev/$disk" ]; then
        log "WARNING: Disk /dev/$disk does not exist"
        return
    fi
    
    # Get SMART data
    log "Getting SMART data for /dev/$disk"
    smart_info=$(smartctl -a "/dev/$disk" 2>&1)
    
    # Check if SMART data is available
    if echo "$smart_info" | grep -q "SMART support is: Unavailable"; then
        log "SMART not available for /dev/$disk"
        return
    fi
    
    # Extract relevant information
    model=$(echo "$smart_info" | grep -i "Device Model" | awk -F': ' '{print $2}')
    if [ -z "$model" ]; then
        model=$(echo "$smart_info" | grep -i "Product" | awk -F': ' '{print $2}')
    fi
    
    serial=$(echo "$smart_info" | grep -i "Serial Number" | awk -F': ' '{print $2}')
    capacity=$(echo "$smart_info" | grep -i "User Capacity" | awk -F': ' '{print $2}' | sed 's/[^0-9.]//g')
    
    # Temperature (may vary by disk type)
    temp=$(echo "$smart_info" | grep -i "Temperature" | head -1 | grep -oE '[0-9]+' | head -1)
    
    # Power on hours
    power_on_hours=$(echo "$smart_info" | grep -i "Power_On_Hours" | grep -oE '[0-9]+' | head -1)
    if [ -z "$power_on_hours" ]; then
        power_on_hours=$(echo "$smart_info" | grep -i "Hours powered on" | grep -oE '[0-9]+' | head -1)
    fi
    
    # Overall health status
    smart_status=$(echo "$smart_info" | grep -i "SMART overall-health" | awk -F': ' '{print $2}')
    
    # Health percentage
    health=$(echo "$smart_info" | grep -i "Remaining_Lifetime_Perc\|Health_Percentage" | grep -oE '[0-9]+' | head -1)
    if [ -z "$health" ]; then
        # Alternative way to get health
        health=$(echo "$smart_info" | grep -A1 "231 Temperature_Celsius" | tail -1 | awk '{print $NF}')
    fi
    
    # If we still don't have health, try to estimate from Wear_Leveling_Count
    if [ -z "$health" ]; then
        health=$(echo "$smart_info" | grep -i "Wear_Leveling_Count" | grep -oE '[0-9]+' | head -1)
    fi
    
    # Pending and reallocated sectors
    pending_sectors=$(echo "$smart_info" | grep -i "Current_Pending_Sector" | grep -oE '[0-9]+' | head -1)
    if [ -z "$pending_sectors" ]; then pending_sectors=0; fi
    
    reallocated_sectors=$(echo "$smart_info" | grep -i "Reallocated_Sector" | grep -oE '[0-9]+' | head -1)
    if [ -z "$reallocated_sectors" ]; then reallocated_sectors=0; fi
    
    # CRC errors
    crc_errors=$(echo "$smart_info" | grep -i "UDMA_CRC_Error" | grep -oE '[0-9]+' | head -1)
    if [ -z "$crc_errors" ]; then crc_errors=0; fi
    
    # Store in database
    sqlite3 "$HISTORY_DB" <<EOF
INSERT OR REPLACE INTO disks (
    date, hostname, device, model, serial, capacity, temperature, 
    power_on_hours, health_percentage, pending_sectors, 
    reallocated_sectors, crc_errors, smart_status
) VALUES (
    '$today', '$HOSTNAME', '$disk', '$model', '$serial', '$capacity', 
    $temp, $power_on_hours, $health, $pending_sectors, 
    $reallocated_sectors, $crc_errors, '$smart_status'
);
EOF
    
    # Generate alerts if needed
    if [ -n "$health" ] && [ "$health" -lt "$ALERT_THRESHOLD" ]; then
        send_alert "Low Disk Health" "Disk /dev/$disk ($model, S/N: $serial) health is at $health%, below threshold of $ALERT_THRESHOLD%"
    fi
    
    if [ "$pending_sectors" -gt 0 ]; then
        send_alert "Pending Sectors Detected" "Disk /dev/$disk ($model, S/N: $serial) has $pending_sectors pending sectors"
    fi
    
    if [ "$reallocated_sectors" -gt 10 ]; then
        send_alert "High Reallocated Sectors" "Disk /dev/$disk ($model, S/N: $serial) has $reallocated_sectors reallocated sectors"
    fi
    
    if [ "$crc_errors" -gt 10 ]; then
        send_alert "CRC Errors Detected" "Disk /dev/$disk ($model, S/N: $serial) has $crc_errors CRC errors"
    fi
    
    if [ "$smart_status" != "PASSED" ]; then
        send_alert "SMART Status Warning" "Disk /dev/$disk ($model, S/N: $serial) SMART status: $smart_status"
    fi
    
    log "Processed SMART data for /dev/$disk ($model, S/N: $serial)"
}

# Function to check mdadm array status
check_mdadm_arrays() {
    local today=$(date +"%Y-%m-%d")
    local mdstat
    
    # Check if mdadm is installed
    if ! command -v mdadm &> /dev/null; then
        log "mdadm not installed, skipping RAID array checks"
        return
    fi
    
    # Read /proc/mdstat
    if [ -f /proc/mdstat ]; then
        mdstat=$(cat /proc/mdstat)
        
        # Extract array information
        echo "$mdstat" | grep "^md" | while read -r line; do
            array_name=$(echo "$line" | awk '{print $1}')
            
            # Get detailed info with mdadm
            array_detail=$(mdadm --detail "/dev/$array_name" 2>/dev/null)
            if [ $? -ne 0 ]; then
                log "Failed to get details for /dev/$array_name"
                continue
            fi
            
            level=$(echo "$array_detail" | grep "Raid Level" | awk '{print $4}')
            status=$(echo "$array_detail" | grep "State" | awk '{print $3}')
            devices=$(echo "$array_detail" | grep "Active Devices" | awk '{print $4}')
            
            # Get space usage
            used_percent=$(df -h "/dev/$array_name" 2>/dev/null | awk 'NR==2 {print $5}' | tr -d '%')
            if [ -z "$used_percent" ]; then
                used_percent=0
            fi
            
            # Store in database
            sqlite3 "$HISTORY_DB" <<EOF
INSERT OR REPLACE INTO arrays (
    date, hostname, array_name, level, devices, status, used_percent
) VALUES (
    '$today', '$HOSTNAME', '$array_name', '$level', '$devices', '$status', $used_percent
);
EOF
            
            # Check if array is degraded
            if [ "$status" != "clean" ] && [ "$status" != "active" ]; then
                send_alert "RAID Array Problem" "Array /dev/$array_name is in $status state"
            fi
            
            # Check space usage
            if [ "$used_percent" -gt 90 ]; then
                send_alert "RAID Array Space Warning" "Array /dev/$array_name is $used_percent% full"
            fi
            
            log "Processed RAID array /dev/$array_name ($level, status: $status)"
        done
    else
        log "No mdadm arrays found (/proc/mdstat not found)"
    fi
}

# Function to check controller hardware
check_controller_hardware() {
    local today=$(date +"%Y-%m-%d")
    
    # Check for LSI/Broadcom MegaRAID controllers
    if command -v storcli &> /dev/null || command -v storcli64 &> /dev/null; then
        local storcli_cmd
        if command -v storcli &> /dev/null; then
            storcli_cmd="storcli"
        else
            storcli_cmd="storcli64"
        fi
        
        log "Checking LSI/Broadcom RAID controllers with $storcli_cmd"
        
        # Get controller list
        local controllers=$($storcli_cmd show 2>/dev/null | grep -E "^[0-9]+" | awk '{print $1}')
        
        for ctrl in $controllers; do
            # Get controller info
            local ctrl_info=$($storcli_cmd /c$ctrl show 2>/dev/null)
            local model=$(echo "$ctrl_info" | grep "Product Name" | awk -F': ' '{print $2}' | xargs)
            local status=$(echo "$ctrl_info" | grep "Status" | awk -F': ' '{print $2}' | xargs)
            local temp=$(echo "$ctrl_info" | grep "Temperature" | awk -F': ' '{print $2}' | grep -oE '[0-9]+' | head -1)
            
            if [ -z "$temp" ]; then temp=0; fi
            
            # Store in database
            sqlite3 "$HISTORY_DB" <<EOF
INSERT OR REPLACE INTO controller_info (
    date, hostname, controller_type, model, status, temperature
) VALUES (
    '$today', '$HOSTNAME', 'PERC', '$model', '$status', $temp
);
EOF
            
            # Alert on issues
            if [ "$status" != "Optimal" ] && [ "$status" != "OK" ]; then
                send_alert "RAID Controller Warning" "Controller $model is in $status state"
            fi
            
            log "Processed PERC RAID controller $model (status: $status)"
        done
    fi
    
    # Check for HP Smart Array controllers with hpssacli/ssacli
    if command -v ssacli &> /dev/null || command -v hpssacli &> /dev/null; then
        local ssacli_cmd
        if command -v ssacli &> /dev/null; then
            ssacli_cmd="ssacli"
        else
            ssacli_cmd="hpssacli"
        fi
        
        log "Checking HP Smart Array controllers with $ssacli_cmd"
        
        # Get controller list
        local ctrl_info=$($ssacli_cmd ctrl all show status 2>/dev/null)
        echo "$ctrl_info" | grep -i "Smart Array" | while read -r line; do
            local model=$(echo "$line" | awk -F': ' '{print $1}' | xargs)
            local status=$(echo "$line" | awk -F': ' '{print $2}' | xargs)
            
            # HP controllers don't always report temperature through this interface
            local temp=0
            
            # Store in database
            sqlite3 "$HISTORY_DB" <<EOF
INSERT OR REPLACE INTO controller_info (
    date, hostname, controller_type, model, status, temperature
) VALUES (
    '$today', '$HOSTNAME', 'SmartArray', '$model', '$status', $temp
);
EOF
            
            # Alert on issues
            if [ "$status" != "OK" ]; then
                send_alert "RAID Controller Warning" "Controller $model is in $status state"
            fi
            
            log "Processed HP Smart Array controller $model (status: $status)"
        done
    fi
}

# Function to clean up old history
cleanup_old_history() {
    # Get retention period from config
    local retention_days=$(jq -r '.history_retention_days' "$CONFIG_FILE")
    if [ -z "$retention_days" ] || [ "$retention_days" = "null" ]; then
        retention_days=365
    fi
    
    local cutoff_date=$(date -d "$retention_days days ago" +"%Y-%m-%d")
    
    # Delete old records
    sqlite3 "$HISTORY_DB" <<EOF
DELETE FROM disks WHERE date < '$cutoff_date';
DELETE FROM arrays WHERE date < '$cutoff_date';
DELETE FROM controller_info WHERE date < '$cutoff_date';
EOF
    
    log "Cleaned up history older than $cutoff_date"
}

# Function to generate a health report
generate_health_report() {
    local today=$(date +"%Y-%m-%d")
    local report_file="$LOG_DIR/health_report_$today.txt"
    
    # Header
    if [[ $PRBL_AVAILABLE == true ]]; then
        # Use PRbL box formatting for reports if available
        {
            set-boxtype "double"
            boxtop
            center "Disk Health Report for $HOSTNAME - $today"
            boxbottom
            
            # Disk summary
            boxtop
            center "DISK HEALTH SUMMARY"
            boxbottom
        } > "$report_file"
        
        # Get disk data
        sqlite3 -header -column "$HISTORY_DB" <<EOF >> "$report_file"
SELECT 
    device, 
    model, 
    temperature, 
    power_on_hours/24 AS power_on_days, 
    health_percentage,
    smart_status
FROM disks 
WHERE date = '$today' AND hostname = '$HOSTNAME'
ORDER BY health_percentage ASC;
EOF
        
        # RAID array summary
        {
            boxtop
            center "RAID ARRAY SUMMARY"
            boxbottom
        } >> "$report_file"
        
        # Get array data
        sqlite3 -header -column "$HISTORY_DB" <<EOF >> "$report_file"
SELECT 
    array_name, 
    level, 
    devices, 
    status, 
    used_percent
FROM arrays 
WHERE date = '$today' AND hostname = '$HOSTNAME';
EOF
        
        # Controller summary
        {
            boxtop
            center "CONTROLLER SUMMARY"
            boxbottom
        } >> "$report_file"
        
        # Get controller data
        sqlite3 -header -column "$HISTORY_DB" <<EOF >> "$report_file"
SELECT 
    controller_type, 
    model, 
    status, 
    temperature
FROM controller_info 
WHERE date = '$today' AND hostname = '$HOSTNAME';
EOF
        
        # Health trends
        {
            boxtop
            center "HEALTH TRENDS (Last 30 days)"
            boxbottom
        } >> "$report_file"
        
    else
        # Traditional formatting
        {
            echo "Disk Health Report for $HOSTNAME - $today"
            echo "=========================================="
            echo ""
            echo "DISK HEALTH SUMMARY:"
            echo "--------------------"
        } > "$report_file"
        
        # Get disk data
        sqlite3 -header -column "$HISTORY_DB" <<EOF >> "$report_file"
SELECT 
    device, 
    model, 
    temperature, 
    power_on_hours/24 AS power_on_days, 
    health_percentage,
    smart_status
FROM disks 
WHERE date = '$today' AND hostname = '$HOSTNAME'
ORDER BY health_percentage ASC;
EOF
        
        {
            echo ""
            echo "RAID ARRAY SUMMARY:"
            echo "------------------"
        } >> "$report_file"
        
        # Get array data
        sqlite3 -header -column "$HISTORY_DB" <<EOF >> "$report_file"
SELECT 
    array_name, 
    level, 
    devices, 
    status, 
    used_percent
FROM arrays 
WHERE date = '$today' AND hostname = '$HOSTNAME';
EOF
        
        {
            echo ""
            echo "CONTROLLER SUMMARY:"
            echo "------------------"
        } >> "$report_file"
        
        # Get controller data
        sqlite3 -header -column "$HISTORY_DB" <<EOF >> "$report_file"
SELECT 
    controller_type, 
    model, 
    status, 
    temperature
FROM controller_info 
WHERE date = '$today' AND hostname = '$HOSTNAME';
EOF
        
        {
            echo ""
            echo "HEALTH TRENDS (Last 30 days):"
            echo "---------------------------"
        } >> "$report_file"
    fi
    
    # Health trends for each disk, regardless of formatting style
    local disks=$(sqlite3 "$HISTORY_DB" "SELECT DISTINCT device FROM disks WHERE hostname = '$HOSTNAME';")
    for disk in $disks; do
        echo "Disk $disk Health Trend:" >> "$report_file"
        sqlite3 -header -column "$HISTORY_DB" <<EOF >> "$report_file"
SELECT 
    date, 
    health_percentage,
    pending_sectors,
    reallocated_sectors
FROM disks 
WHERE hostname = '$HOSTNAME' AND device = '$disk'
ORDER BY date DESC
LIMIT 30;
EOF
        echo "" >> "$report_file"
    done
    
    log "Health report generated at $report_file"
    return 0
}

# Main function
main() {
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --interactive|-i)
                # Run interactive mode
                interactive_mode
                exit 0
                ;;
            --led|-l)
                # LED control
                if [[ -z "$2" || -z "$3" ]]; then
                    echo "Usage: $0 --led <disk> <on|blink|off>"
                    exit 1
                fi
                disk_led_control "$2" "$3"
                exit $?
                ;;
            --test|-t)
                # Run SMART test
                if [[ -z "$2" || -z "$3" ]]; then
                    echo "Usage: $0 --test <disk> <short|long|conveyance|offline|status|abort>"
                    exit 1
                fi
                run_disk_test "$2" "$3"
                exit $?
                ;;
            --help|-h)
                # Display help
                echo "Disk Health Monitoring System"
                echo ""
                echo "Usage: $0 [options]"
                echo ""
                echo "Options:"
                echo "  -i, --interactive    Run in interactive mode with menus"
                echo "  -l, --led DISK ACTION    Control disk LED (on|blink|off)"
                echo "  -t, --test DISK TYPE     Run SMART test (short|long|conveyance|offline|status|abort)"
                echo "  -h, --help           Display this help message"
                echo ""
                echo "Without options, performs a full system scan and generates reports."
                exit 0
                ;;
            *)
                # Unknown option
                echo "Unknown option: $1"
                echo "Use --help for usage information."
                exit 1
                ;;
        esac
        shift
    done

    if [[ $PRBL_AVAILABLE == true ]]; then
        set-boxtype "rounded"
        boxtop
        center "Starting disk health monitoring on $HOSTNAME"
        boxbottom
    else
        log "Starting disk health monitoring on $HOSTNAME"
    fi
    
    # Check all physical disks
    log "Scanning physical disks..."
    for disk in $(lsblk -d -o NAME -n | grep -v "loop" | grep -v "sr"); do
        get_smart_data "$disk"
    done
    
    # Check mdadm arrays
    log "Checking mdadm arrays..."
    check_mdadm_arrays
    
    # Check controller hardware
    log "Checking controller hardware..."
    check_controller_hardware
    
    # Clean up old history
    cleanup_old_history
    
    # Generate health report
    log "Generating health report..."
    generate_health_report
    
    log "Disk health monitoring completed"
}

# Run main function
main "$@"

exit 0