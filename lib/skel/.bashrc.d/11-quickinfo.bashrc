#!/bin/bash

###############################################################
# MOTD/Login Quick Information script                         #
# This script pulls information from a variety of sources     #
# in the a linux system, and aggregates it into a small table #
# that is displayed upon terminal login to the system.        #
#                                                             #
#           Written by Alan "pyr0ball" Weinstock              #
###############################################################

quickinfo_version=2.0.3
prbl_functons_req_ver=1.1.3

# Uses a wide variety of methods to check which distro this is run on
# TODO: Add alternative handling for other environments
if type lsb_release >/dev/null 2>&1; then
  # linuxbase.org
  OS=$(lsb_release -si)
  VER=$(lsb_release -sr)
elif [ -f /etc/debian_version ]; then
  # Older Debian/Ubuntu/etc.
  OS=Debian
  VER=$(cat /etc/debian_version)
elif [ -f /etc/os-release ]; then
  # freedesktop.org and systemd
  . /etc/os-release
  OS=$NAME
  VER=$VERSION_ID
elif [ -f /etc/lsb-release ]; then
  # For some versions of Debian/Ubuntu without lsb_release command
  . /etc/lsb-release
  OS=$DISTRIB_ID
  VER=$DISTRIB_RELEASE
elif [ -f /etc/debian_version ]; then
  # Older Debian/Ubuntu/etc.
  OS=Debian
  VER=$(cat /etc/debian_version)
elif [ -f /etc/SuSe-release ]; then
  # Older SuSE/etc.
  ...
elif [ -f /etc/redhat-release ]; then
  # Older Red Hat, CentOS, etc.
  ...
else
  # Fall back to uname, e.g. "Linux <version>", also works for BSD, etc.
  OS=$(uname -s)
  VER=$(uname -r)
fi

# Locate and import settings (shares same name with script apart from file extension)
scriptname="${0##*/}"
rundir="${0%/*}"
# If running on login as a bashrc, the above variables will not give this script's data
# Failover hardcoded settings location for now if running from login environment

### TODO: This implementation is still broken. context for location breaks during login
# if ! [[ $scriptname =~ "-bash" ]] ; then
#   #rundir_absolute=$(cd $rundir && pwd)
#   rundir_absolute=$(pushd $rundir && pwd && popd)
#   settingsfile=$(echo "$rundir_absolute/$scriptname" | sed -E 's/(.*)bashrc/\1settings/')
# else
#   if ! [ -f "$HOME/.bashrc.d/11-quickinfo.settings"] ; then
#     settingsfile="$HOME/.bashrc.d/11-quickinfo.settings"
#   else
    # default quickinfo bashrc Preferences

    # Disable run on non-interactive sessions (set true to disable)
    interactive_only=false

    # Network Adapter Preferences

    # set false to hide network adapters without valid IP's
    show_disconnected=true

    # Ignored network adapter names (regex match)
    # separate adapter names with '\|' ex. "lo\|tun0"
    filtered_adapters="lo"

    # Disks
    # separate disk types with '\|' ex. "sd\|nvme"
    allowed_disk_prefixes="sd\|md\|mapper\|nvme\|mmcblk\|root"
    disallowed_disks="boot"
#   fi
# fi
# source $settingsfile

# source PRbL functions
if [ ! -z $prbl_functions ] ; then
  source $prbl_functions
else
  # Failover if global variable is not defined. Checks for 'functions' in same location
  echo -e "PRbL functions not defined. Check ~/.bashrc"
  if [ -f "$rundir/functions" ] ; then
    source $rundir/functions
  else
    echo -e "local functions file also missing. Some visual elements will be missing"
  fi
fi

# check PRbL functions version
if [[ $(vercomp $functionsrev $prbl_functons_req_ver) == 2 ]] ; then
  warn "PRbL functions installed are lower than recommended ($prbl_functons_req_ver)"
  warn "Some features may not work as expected"
else
  if ! vercomp 1 1 ; then
    warn "PRbL functions library is older than 1.1.3, please update!"
    warn "Some features may not work as expected"
  fi
fi

################################

# Help - displayed when user inputs the -h option, or upon
# running this script with an invalid argument

read -r -d '' usage << EOF
$scriptname [-h] -- Displays information relevent to the system upon login

Usage:
    -h  show this help text
EOF

################################

# Options parser

while getopts ":h" opt
	do
		case ${opt} in
			h)	echo "$usage"
				exit
				;;
			:)	
				;;
			\?)	printf "illegal option: -%s\n" "$OPTARG" >&2
				echo "$usage" >&2
				exit 1
				;;
			esac
		done
		shift $((OPTIND - 1))

################################

# Uncomment this section to disable running this in non-interactive sessions
# For example, on automated logins for a git process, the entire output of
# this script will be written to logs. Disabling non-interactive sessions
# will prevent this script from clogging the logging, but it also can cause
# unexpected exits if improperly deployed (immediate exit on ssh login)
#if [[ $interactive_only == true ]] ; then
#  [[ "$-" == *i* ]] || fail "non-interactive session"
#fi
################################

# Global parameters pulled from cache file
  location=$(uname -a | awk '{print $2}')
  image_version=$(uname -r)
  software_version=$(echo $OS $VER)
# Checks if variables are empty and fills the variables
# with generic warning

empty_var="MISSING"

if [ -z "$location" ]
	then
		location=$empty_var
		any_missing=true
fi
if [ "$any_missing" == "true" ]
	then
		vars_missing=$(echo "Something went wrong gathering information")
fi

# Gets public IP address using opendns
# TODO: optimize this to run after time delay using timestamp in settings
set_spinner spinner19
#spin "eval $(wan_ip=$(wget -qO- http://ipecho.net/plain \| xargs echo ))"
wan_ip=$(wget -qO- http://ipecho.net/plain \| xargs echo )

# Checks memory usage
mem_usage=$(free -m | grep Mem | awk '{print $3"M/"$2"M"}')

# Grab number of CPU's for calculating total system load
num_cpus=$(lscpu | grep -v node | grep CPU\(s\)\: | awk '{print $2}')

# Checks load averages using uptime, cuts out the load
# average numbers and prints them as percentages after
# accounting for CPU threads
load_check=$(uptime | sed -r 's|.*load average: ([\.0-9]+), ([\.0-9]+), ([\.0-9]+)|\1 \2 \3|g')
load_averages=$(echo "$load_check $num_cpus" | awk '{printf "5min: %.0f%% ", $1/$4*100} {printf "10min: %.0f%% ", $2/$4*100} {printf "15min: %.0f%%", $3/$4*100}' ORS=' ')

# Alternate CPU Utilization Calculation
# Read /proc/stat file (for first datapoint)
read cpu user nice system idle iowait irq softirq steal guest< /proc/stat

# compute active and total utilizations
cpu_active_prev=$((user+system+nice+softirq+steal))
cpu_total_prev=$((user+system+nice+softirq+steal+idle+iowait))

sleep 1

# Read /proc/stat file (for second datapoint)
read cpu user nice system idle iowait irq softirq steal guest< /proc/stat

# compute active and total utilizations
cpu_active_cur=$((user+system+nice+softirq+steal))
cpu_total_cur=$((user+system+nice+softirq+steal+idle+iowait))

# compute CPU utilization (%)
cpu_util=$((100*( cpu_active_cur-cpu_active_prev ) / (cpu_total_cur-cpu_total_prev) ))

# Checks system uptime
if [[ "$(uptime | grep -iq day ; echo $?)" == "0" ]] ; then
    # first logic gate, if the system has been online for at least a day
    if [[ "$(uptime | grep -iq min ; echo $?)" == "0" ]] ; then
        # nested logic gate. If the system has been online for more than a day
        # but less than a day and an hour, the tokens shift and requires alternate parsing
        s_uptime=$(uptime | awk '{print $3 " " $4 " " $5 " Minutes"}')
    else # gate for if the system has been online longer than one day and one hour
        s_uptime=$(uptime | awk '{print $3 " " $4 " " $5 " Hours"}')
    fi
else # logic gate for if the system has been online less than a day but more than an hour
    if [[ "$(uptime | grep -iq min ; echo $?)" == "1" ]] ; then
        s_uptime=$(uptime | awk '{print $3 " Hours  "}')
    else
        s_uptime=$(uptime | awk '{print $3 " Minutes    "}')
    fi
fi


# Checks CPU temperature
cputemp=$(printf "%d" $(sensors | grep -m 1 Core\ 0 | awk '{print $3}') 2> /dev/null)
# Checks CPU and CXPS temperatures,changes output text to warn user if temperatures
# are too high (greater than 65°C is considered hot)
if [[ "$cputemp" -gt "65" ]] ; then
    cputemp="${ong}${blk}${cputemp}°C${dfl}"
else
    cputemp="${cputemp}°C"
fi

################################

# Check for release upgrade
if [ -x /usr/lib/ubuntu-release-upgrader/release-upgrade-motd ]; then
    if [ -f /var/lib/ubuntu-release-upgrader/release-upgrade-available ] ; then
        release_upgrade=$(cat /var/lib/ubuntu-release-upgrader/release-upgrade-available)
    fi
fi
if [ "$(lsb_release -sd | cut -d ' ' -f4)" = "(development" ]; then
    unset release_upgrade
fi

################################

# Check for fsck message
if [ -x /usr/lib/update-notifier/update-motd-fsck-at-reboot ]; then
    fsck_needed=`exec /usr/lib/update-notifier/update-motd-fsck-at-reboot`
fi

################################

# Check if reboot required by updates
if [ -f /var/run/reboot-required ]; then
    reboot_required=$(cat /var/run/reboot-required)
fi

################################

# Network display and filtering

declare -a adapters=()
declare -a ips=()
declare -a macs=()
declare -a ifups=()
for device in $(ls /sys/class/net/ | grep -v "$filtered_adapters") ; do
  adapters+=($device)
  _ip=$(ip -f inet -o addr show $device | cut -d\  -f 7 | cut -d/ -f 1 | head -n 1)
  if valid-ip $_ip ; then
    ips=(${ips[@]} "$_ip")
    ifups=(${ifups[@]} "up")
  else
    ips=(${ips[@]} "${red}disconnected${dfl}")
    ifups=(${ifups[@]} "down")
  fi
  macs=(${macs[@]} "$(cat /sys/class/net/${device}/address)")
done

################################

# Disk array setup
declare -a logicals=()
declare -a mounts=()
declare -a usages=()
declare -a freespaces=()
diskinfo=$(/bin/df -h | grep "$allowed_disk_prefixes" | grep -v "$disallowed_disks")
logicals=($(cut -d ' ' -f1 <<< "${diskinfo}"))
mounts=($(awk '{print $6}' <<< "${diskinfo}"))
usages=($(awk '{print $5}' <<< "${diskinfo}"))
freespaces=($(awk '{print $4}' <<< "${diskinfo}"))

################################
#check for updates
packages=$(/usr/lib/update-notifier/apt-check --human-readable | grep "can be")
supdates=$(/usr/lib/update-notifier/apt-check --human-readable | grep "security updates" | cut -d '.' -f1)
packages=${packages%%\.*}
supdates=${supdates%%\.*}
# Check for updates
if [[ $(echo ${packages} | grep -c updates) != 1 ]] || [ -z "${supdates}" ] || [ -z "${release_upgrade}" ] ; then
#if [[ $(echo ${packages} | grep -c ^0\ updates) == 1 ]] ; then
  need_updates=false
else
  need_updates=true
fi

# Begin echo out of formatted table with aggregated information 

boxtop
boxline ""
boxline "${bld}${unl}Location:${dfl}  ${grn}${unl}$location${dfl}"
boxline ""
# Echo out network arrays
for((i=0; i<"${#adapters[@]}"; i++ )); do
  if [[ $show_disconnected != true ]] ; then
    if [[ ${ifups[$i]} == up ]] ; then
	    boxline "	${adapters[$i]}: ${cyn}${ips[$i]}${dfl}\t|  ${blu}${macs[$i]}${dfl}"
    fi
  else
    boxline "	${adapters[$i]}: ${cyn}${ips[$i]}${dfl}\t|  ${blu}${macs[$i]}${dfl}"
  fi
done
boxline "	WAN IP:	${ylw}${wan_ip}${dfl}"
boxline ""
boxline "${bld}${unl}Linux Info${dfl}"
boxline "	Kernel Ver: ${pur}${image_version}${dfl}	|  OS Ver: ${ong}${software_version}${dfl}"
boxline ""
boxline "${bld}${unl}System Status${dfl}"
boxline "	System Load: ${load_averages}"
boxline "	CPU Temp: ${lbl}${cputemp}${dfl}	|  Utilization: ${lrd}${cpu_util}%${dfl}"
boxline "	Memory used/total: ${mem_usage}"
boxline "	${unl}Disk Info:${dfl}"
boxline "${unl}$(printf '\t|%-4s\t%-4s\t%-4s\t%-4s\n' Usage Free Mount Volumes)${dfl}"
for((i=0; i<"${#logicals[@]}"; i++ )); do
  boxline "\t$(printf '|%-4s\t%-4s\t%-4s\t%-4s\n' ${usages[$i]} ${freespaces[$i]} ${mounts[$i]} ${logicals[$i]})"
done
boxline ""
if [[ "$need_updates" == "true" ]] ; then
  boxline "${bld}${unl}Updates${dfl}"
  boxline "	${packages}"
  boxline "	${supdates}"
  boxline "	${release_upgrade}"
fi
if [ -z "${fsck_needed}" ] || [ -z "${reboot_required}" ] ; then
  boxline "	${fsck_needed}${reboot_required}"
fi
boxbottom
