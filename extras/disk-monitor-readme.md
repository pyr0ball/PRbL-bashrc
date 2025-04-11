## Interactive Mode

The disk health monitoring system includes an interactive mode with comprehensive menus for managing your disks. This mode leverages the PRbL menu functions and allows you to:

1. **View disk information**: See a complete list of all disks with their health status
2. **Control disk LEDs**: Turn on, blink, or turn off the identification LEDs on your disks
3. **Run SMART tests**: Start various diagnostic tests and monitor their progress
4. **Scan individual disks**: Check the health of specific disks on demand

To use interactive mode:

```bash
sudo /usr/local/bin/disk-health-monitor.sh --interactive
# or more simply
sudo /usr/local/bin/disk-health-monitor.sh -i
```

### LED Control

The system supports controlling disk identification LEDs through various methods (ledctl, sg_ses, smartctl, hdparm) depending on your hardware. This is useful for physically identifying a specific disk in your system.

From the command line:

```bash
# Turn on the LED for a specific disk
sudo /usr/local/bin/disk-health-monitor.sh --led sda on

# Make the LED blink
sudo /usr/local/bin/disk-health-monitor.sh --led sda blink

# Turn off the LED
sudo /usr/local/bin/disk-health-monitor.sh --led sda off
```

Or use the interactive menu for more options, including controlling LEDs for all disks simultaneously.

### SMART Testing

The system can run various SMART diagnostic tests on your disks:

- **Short**: Quick assessment (~2 minutes)
- **Long**: Comprehensive surface scan (hours)
- **Conveyance**: Test for physical damage during shipping (~5 minutes)
- **Offline**: Background collection of performance data

From the command line:

```bash
# Run a short test
sudo /usr/local/bin/disk-health-monitor.sh --test sda short

# Check test status
sudo /usr/local/bin/disk-health-monitor.sh --test sda status

# Abort a running test
sudo /usr/local/bin/disk-health-monitor.sh --test sda abort
```

The interactive menu provides more options, including running tests on all disks simultaneously.# Disk Health Monitoring System

A comprehensive solution for monitoring disk health, mdadm RAID arrays, and storage controller hardware on Ubuntu systems. The system tracks SMART data, keeps historical records for health trend analysis, and provides multiple notification channels for alerts.

## Features

- **Comprehensive Monitoring**:
  - SMART status for all disk types
  - mdadm RAID array status and usage
  - RAID controller hardware status (LSI/Broadcom, Dell PERC, HP Smart Array)

- **Historical Tracking**:
  - Records health metrics over time in a SQLite database
  - Tracks degradation patterns
  - Monitors disk aging trends

- **Multiple Alert Methods**:
  - Email notifications
  - Signal messenger (via signal-cli)
  - Telegram bot integration

- **Smart Reporting**:
  - Daily health reports
  - Historical health trends
  - Integration with PRbL for enhanced output (if available)

## System Requirements

- Ubuntu 24.x (or other Debian-based distributions)
- Required packages (installed automatically):
  - smartmontools
  - mdadm (if using RAID)
  - sqlite3
  - sendmail
  - jq
  - curl

## Installation

### Option 1: Using the PRbL-style Extra Install

The recommended installation method for systems with PRbL-bashrc installed:

```bash
# Clone the repository
git clone https://your-repo-url.git

# Navigate to the directory
cd disk-health-monitor

# Run the installer
sudo ./disk-monitor.install
```

### Option 2: Manual Installation

1. Copy the main script to a suitable location:
   ```bash
   sudo cp disk-health-monitor.sh /usr/local/bin/
   sudo chmod +x /usr/local/bin/disk-health-monitor.sh
   ```

2. Create necessary directories:
   ```bash
   sudo mkdir -p /etc/disk-health /var/log/disk-health /var/lib/disk-health
   ```

3. Create a basic configuration:
   ```bash
   sudo bash -c 'cat > /etc/disk-health/config.json' << EOF
   {
       "email_alerts": true,
       "signal_alerts": false,
       "telegram_alerts": false,
       "alert_threshold": 20,
       "email_recipient": "your-email@example.com",
       "signal_number": "",
       "telegram_bot_token": "",
       "telegram_chat_id": "",
       "check_interval_days": 1,
       "history_retention_days": 365,
       "ignore_disks": []
   }
   EOF
   ```

4. Create systemd service and timer:
   ```bash
   sudo bash -c 'cat > /etc/systemd/system/disk-health-monitor.service' << EOF
   [Unit]
   Description=Disk Health Monitoring System
   After=network.target

   [Service]
   Type=oneshot
   ExecStart=/usr/local/bin/disk-health-monitor.sh
   User=root
   Group=root

   [Install]
   WantedBy=multi-user.target
   EOF

   sudo bash -c 'cat > /etc/systemd/system/disk-health-monitor.timer' << EOF
   [Unit]
   Description=Run Disk Health Monitoring System daily
   Requires=disk-health-monitor.service

   [Timer]
   Unit=disk-health-monitor.service
   OnCalendar=*-*-* 01:00:00
   RandomizedDelaySec=1800
   Persistent=true

   [Install]
   WantedBy=timers.target
   EOF
   ```

5. Enable and start the timer:
   ```bash
   sudo systemctl daemon-reload
   sudo systemctl enable disk-health-monitor.timer
   sudo systemctl start disk-health-monitor.timer
   ```

## Configuration

The configuration file is located at `/etc/disk-health/config.json`. You can modify the following parameters:

| Parameter | Description | Default |
|-----------|-------------|---------|
| `email_alerts` | Whether to send email alerts | `true` |
| `signal_alerts` | Whether to send Signal messenger alerts | `false` |
| `telegram_alerts` | Whether to send Telegram alerts | `false` |
| `alert_threshold` | Health percentage threshold for triggering alerts | `20` |
| `email_recipient` | Email address to receive alerts | `admin@example.com` |
| `signal_number` | Signal phone number for notifications | `""` |
| `telegram_bot_token` | Telegram bot token | `""` |
| `telegram_chat_id` | Telegram chat ID | `""` |
| `check_interval_days` | Days between checks (for reference only) | `1` |
| `history_retention_days` | Days to keep historical data | `365` |
| `ignore_disks` | Array of disk names to ignore (e.g., ["sda", "sdb"]) | `[]` |

## Using Signal Notifications

To use Signal notifications:

1. Install signal-cli (the installer will attempt to do this)
2. Register your number with signal-cli:
   ```bash
   signal-cli -u "+1234567890" register
   ```
3. Verify the registration with the code you receive:
   ```bash
   signal-cli -u "+1234567890" verify CODE
   ```
4. Update the configuration file to enable Signal alerts and set your number.

## Using Telegram Notifications

To use Telegram notifications:

1. Create a bot using @BotFather on Telegram
2. Note the bot token
3. Find your chat ID (send a message to @userinfobot)
4. Update the configuration file with your bot token and chat ID
5. The installer will test the connection if you provide these details during setup

## Usage

The system runs automatically daily via the systemd timer. You can also run it manually:

```bash
sudo /usr/local/bin/disk-health-monitor.sh
```

## Logs and Reports

- Logs are stored in `/var/log/disk-health/disk-health.log`
- Daily health reports are stored in `/var/log/disk-health/health_report_YYYY-MM-DD.txt`
- The SQLite database is stored in `/var/lib/disk-health/history.db`

You can query the database directly for custom reports:

```bash
sqlite3 /var/lib/disk-health/history.db "SELECT * FROM disks WHERE device='sda' ORDER BY date DESC LIMIT 10;"
```

## Troubleshooting

If you encounter issues:

1. Check the log file:
   ```bash
   cat /var/log/disk-health/disk-health.log
   ```

2. Test the service manually:
   ```bash
   sudo /usr/local/bin/disk-health-monitor.sh
   ```

3. Verify the systemd timer is active:
   ```bash
   systemctl status disk-health-monitor.timer
   ```

4. Check if required packages are installed:
   ```bash
   dpkg -l smartmontools mdadm sqlite3 sendmail jq curl
   ```

## Notes for Navi and Heimdall

This monitoring system has been specifically configured for the Ubuntu 24 systems running on Navi and Heimdall. Additional customizations for these systems may be included in the future.

## License

This software is provided under the MIT License. Feel free to modify and distribute it according to your needs.