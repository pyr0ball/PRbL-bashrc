#!/bin/bash

###############################################################
# MOTD/Login Quick Information script                         #
# This script pulls information from a variety of sources     #
# in the a linux system, and agregates it into a small table  #
# that is displayed upon terminal login to the system.        #
#                                                             #
#           Written by Alan "pyr0ball" Weinstock              #
###############################################################

scriptname=${0##*/}
rundir=$(cd `dirname $0` && pwd)
source $prbl_functions

# Set to only run on interactive sessions (Disabled as cache
# generation is non-interactive, so this would cause outdated
# information to be displayed)
#[[ "$-" == *i* ]] || exit 0

# Cache File Parameters
cachefile=quickinfo.cache
cachefile_location=$HOME/.quickinfo
if [ ! -d $cachefile_location ] ; then
  mkdir -p $cachefile_location
fi
cache=$(echo "${cachefile_location}/${cachefile}")

### Functions table

################################

warn(){
	ec=$?
	[ "${ec}" == "0" ] && ec=1
	echo "WARNING[code=$ec}: $@"
}

################################

quickinfo-cache (){
#check for updates
packages_cache=$(/usr/lib/update-notifier/apt-check --human-readable | grep "can be")
supdates_cache=$(/usr/lib/update-notifier/apt-check --human-readable | grep "security updates")
# Uses a wide variety of methods to check which distro this is run on
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

  # Echo the parameters out to the cache file with a "key" marker
  # at the beginning of the line. This key is used to pull the specific
  # line needed for each parameter using grep, then cut out of the
  # final echo. Please do not add or remove white space to the beginning of
  # the lines if this is modified in future.
  echo "
  OS${OS}
  VER${VER}
  CACHEPACK${packages_cache}
  CACHESUPD${supdates_cache}" > $cache || fail
}

################################

# Help - displayed when user inputs the -h option, or upon
# running this script with an invalid argument

read -r -d '' usage << EOF
$scriptname [-h] [-c] [-d] -- Displays information relevent to the IDSS system upon login

Usage:
    -h  show this help text
    -c  Pulls new information requiring more time, then stores
        it to the cache file before running
    -d  Run using information stored in ${cache}

EOF

################################

# Options parser

while getopts ":cdh" opt
	do
		case ${opt} in
			h)	echo "$usage"
				exit
				;;
			c)	quickinfo-cache
				;;
			d)	
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

# Checks if cachefile exists yet, and if not, warns the user
if [ ! -f $cache ] ; then
	cachemissing=$(echo "Quickinfo cache file is inaccessible. some information may be missing")
fi

### All curl functions have been migrated to quickinfo-cache function

################################

# Global parameters pulled from cache file
  packages=$(cat ${cache} | grep CACHEPACK | cut -c 12- )
  supdates=$(cat ${cache} | grep CACHESUPD | cut -c 12- )
  location=$(uname -a | awk '{print $2}')
  image_version=$(uname -r)
  OS=$(cat ${cache} | grep OS | cut -c 5- )
  VER=$(cat ${cache} | grep VER | cut -c 6- )
  software_version=$(echo $OS $VER)
# Checks if variables are empty (due to webapp being down on last
# cache run or other possible reasons) and fills the variables
# with generic warning

empty_var="MISSING"

if [ -z "$location" ]
	then
		location=$empty_var
		any_missing=true
fi
if [ -z "$router_version" ]
	then
		router_version=$empty_var
		any_missing=true
fi
if [ -z "$cxps_serial" ]
	then
		cxps_serial=$empty_var
		any_missing=true
fi
if [ "$any_missing" == "true" ]
	then
		vars_missing=$(echo "Something went wrong gathering information. Check WebApp")
fi

# Gets public IP address using opendns
wan_ip=$(wget -qO- http://ipecho.net/plain | xargs echo)

# Global parameters using methods that do not require WebApp
### These functions run each time the script is run, regardless of caching option

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
    release_upgrade=`exec /usr/lib/ubuntu-release-upgrader/release-upgrade-motd`
fi
if [ "$(lsb_release -sd | cut -d' ' -f4)" = "(development" ]; then
    unset release_upgrade
fi

################################

# Check for fsck message
if [ -x /usr/lib/update-notifier/update-motd-fsck-at-reboot ]; then
    fsck_needed=`exec /usr/lib/update-notifier/update-motd-fsck-at-reboot`
fi

################################

# Check if reboot required by updates
if [ -x /usr/lib/update-notifier/update-motd-reboot-required ]; then
    reboot_required=`exec /usr/lib/update-notifier/update-motd-reboot-required`
fi

################################

# Begin echo out of formatted table with agregated information 

boxtop
boxline ""
boxline "${bld}${unl}Location:${dfl}  ${grn}${unl}$location${dfl}"
boxline ""
boxline "${bld}${unl}Network${dfl}"
for i in $(ls /sys/class/net/ | grep -v "lo") ; do 
	boxline "	$i: ${cyn}$(/sbin/ifconfig $i 2> /dev/null | grep broadcast | awk '{print $2}' | cut -f 2 -d ":" |cut -f 1 -d " " )${dfl}	|  ${blu}$(/sbin/ifconfig $i | grep ether | awk '{print $2}')${dfl}"
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
boxline "	Disk Usage:"
for i in $(/bin/df -h | grep "sd\|md\|mapper\|nvme" | awk '{print $1}') ; do
boxline "	`/bin/df -h | grep $i | awk '{print $5}'` $i: `/bin/df -h | grep $i | awk '{print $6}'`"
done
boxline ""
if [[ $(echo ${packages} | grep -c ^0\ updates) != 1 ]] || [ -z "${supdates}"] || [ -z "${release_upgrade}" ] ; then
#if [[ $(echo ${packages} | grep -c ^0\ updates) == 1 ]] ; then
  need_updates=false
else
  need_updates=true
fi
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
