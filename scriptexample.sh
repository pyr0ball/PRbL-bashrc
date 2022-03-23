#!/bin/bash

# Moxa NPort Driver loader and watchdog script

# initial vars
scriptname=${0##*/}
rundir=${0%/*}

source ${rundir}/functions

#-----------------------------------------------------------------#
# Script-specific Parameters
#-----------------------------------------------------------------#

VERSION=1.0
logfile=/var/log/bdv/moxaloader.log
ratelimit=15
rst_threshold=1
god=/opt/ruby-enterprise/bin/god
pingfile=/usr/lib/npreal2/driver/pingup
daemonpid=$(ps -ef | grep -v grep | grep moxaloader.*daemon | awk {'print $2'})
config_sh=$(grep DNS /.AVC-X/etc/networking/profiles/default/ifcfg-Public)
resolv_conf=$(grep nameserver /.AVC-X/etc/networking/profiles/default/resolv.conf)
config_dev=$(grep DNS /.AVC-X/etc/networking/devices/ifcfg-Public)
sys_resolv_conf=$(grep nameserver /etc/resolv.conf)
etc_net_sh=$(grep DNS /etc/network-scripts/ifcfg-Public)
dns=$(grep DNS1 /.AVC-X/etc/networking/profiles/default/ifcfg-Public | cut -c 6-)

#-----------------------------------------------------------------#
# Script-specific Funcitons
#-----------------------------------------------------------------#


usage(){
  boxtop
  boxline "${lyl}Moxa NPort Watchdog & Recovery v$VERSION${dfl}"
  boxseparator
  boxline "Usage:"
  boxline "$scriptname [FUNCTIONS][-d|--daemon|--usage|--version]"
  boxseparator
  boxline "-s | --start - Initializes the Moxa NPort Driver only and exits"
  boxline "-S | --stop - stops the NPort driver and any ongoing daemonized watchdog"
  boxline "-r | --restart - Restarts all BDV hardware services, and re-initialized moxa if DNS is valid"
  boxline "-R | --force-restart - forces a restart of both the NPort driver and BDV services (assume -9)"
  boxline "-p | --ping - Detect nPort online and write 'pingup' file if true or remove if false"
  boxline "-P | --pid - returns the PID's of any ongoing NPort Driver processes"
  boxline "-d | --daemon - daemonizes the service as a watchdog"
  boxline "-F | --fix-dns - Checks system's DNS config and removes entries if invalid"
  boxline "-u | --usage - Show this help text"
  boxline "-h | --help - Show this help text"
  boxline "-v | --version - returns the version of this script"
  boxbottom
}

removedns(){
	# Look for existing DNS entries if there are any
	config_sh=$(grep DNS /.AVC-X/etc/networking/profiles/default/ifcfg-Public)
	resolv_conf=$(grep nameserver /.AVC-X/etc/networking/profiles/default/resolv.conf)
	resolv_search=$(grep search /.AVC-X/etc/networking/profiles/default/resolv.conf)
	config_dev=$(grep DNS /.AVC-X/etc/networking/devices/ifcfg-Public)
	sys_resolv_conf=$(grep nameserver /etc/resolv.conf)
	sys_resolv_search=$(grep search /etc/resolv.conf)
	etc_net_sh=$(grep DNS /etc/network-scripts/ifcfg-Public)
	# Checks if the above variables are empty, and if all are, exits the function only
	if [[ -z "$config_sh" && -z "$resolv_conf" && -z "$resolv_search" && -z "$config_dev" && -z "$sys_resolv_conf" && -z "$sys_resolv_search" && -z "$etc_net_sh" ]] ; then
		logger  echo -e "${grn}No DNS entries found${dfl}"
		return 0
	else
    # If either of the above variables are not empty, proceeds with checking
    # and printing their contents
    if [[ ! -z "$config_sh" ]] ; then
      logger echo -e "${lbl}Current DNS is set to:${dfl}"
      logger echo -e "$config_sh"
      # sed uses regex to detect and delete lines out of the configuration script
      # files that contain DNS entries
      sudo sed -i '/DNS/d' /.AVC-X/etc/networking/profiles/default/ifcfg-Public && logger echo -e "${ylw}Successfully removed DNS entries from ifcfg-Public${dfl}\n" || logger fail "${red}Unable to remove DNS entries from /.AVC-X/etc/networking/profiles/default/ifcfg-Public${dfl}"
    fi
    if [[ ! -z "$resolv_conf" ]] ; then
      logger echo -e "${lbl}Current resolv.conf entry is${dfl}"
      logger echo -e "$resolv_conf"
      sudo sed -i '/nameserver/d' /.AVC-X/etc/networking/profiles/default/resolv.conf && logger echo -e "${ylw}Successfully removed DNS entries from resolv.conf${dfl}\n"  || logger warn "${red}Unable to remove DNS entries from /.AVC-X/etc/networking/profiles/default/resolv.conf${dfl}"
    fi
    if [[ ! -z "$resolv_conf" ]] ; then
      logger echo -e "${lbl}Current resolv.conf is searching${dfl}"
      logger echo -e "$resolv_search"
      sudo sed -i '/search/d' /.AVC-X/etc/networking/profiles/default/resolv.conf && logger echo -e "${ylw}Successfully removed DNS entries from resolv.conf${dfl}\n"  || logger warn "${red}Unable to remove DNS entries from /.AVC-X/etc/networking/profiles/default/resolv.conf${dfl}"
    fi
    if [[ ! -z "$config_dev" ]] ; then
      logger echo -e "${lbl}Current DNS is set to:${dfl}"
      logger echo -e "$config_dev"
      # sed uses regex to detect and delete lines out of the configuration script
      # files that contain DNS entries
      sudo sed -i '/DNS/d' /.AVC-X/etc/networking/devices/ifcfg-Public && logger echo -e "${ylw}Successfully removed DNS entries from ifcfg-Public${dfl}\n" || logger fail "${red}Unable to remove DNS entries from /.AVC-X/etc/networking/devices/ifcfg-Public${dfl}"
    fi
    if [[ ! -z "$sys_resolv_conf" ]] ; then
      logger echo -e "${lbl}Current resolv.conf entry is${dfl}"
      logger echo -e "$sys_resolv_conf"
      sudo sed -i '/nameserver/d' /.AVC-X/etc/networking/profiles/default/resolv.conf && logger echo -e "${ylw}Successfully removed DNS entries from /etc/resolv.conf${dfl}\n"  || logger warn "${red}Unable to remove DNS entries from /etc/resolv.conf${dfl}"
    fi
    if [[ ! -z "$sys_resolv_search" ]] ; then
      logger echo -e "${lbl}Current resolv.conf is searching${dfl}"
      logger echo -e "$sys_resolv_search"
      sudo sed -i '/search/d' /.AVC-X/etc/networking/profiles/default/resolv.conf && logger echo -e "${ylw}Successfully removed DNS entries from /etc/resolv.conf${dfl}\n"  || logger warn "${red}Unable to remove DNS entries from /etc/resolv.conf${dfl}"
    fi
    if [[ ! -z "$etc_net_sh" ]] ; then
      logger echo -e "${lbl}Current DNS is set to:${dfl}"
      logger echo -e "$etc_net_sh"
      # sed uses regex to detect and delete lines out of the configuration script
      # files that contain DNS entries
      sudo sed -i '/DNS/d' /etc/network-scripts/ifcfg-Public && logger echo -e "${ylw}Successfully removed DNS entries from ifcfg-Public${dfl}\n" || logger fail "${red}Unable to remove DNS entries from /.AVC-X/etc/networking/profiles/default/ifcfg-Public${dfl}"
    fi
    return 1
  fi
}

dnscheck(){
  # The Moxa drivers are built in such a way that they will hang if no outside
  # network is available, unless DNS entries are not present. Below checks for
  # external network access, then removes dns entries if outside network is unavailable

  # Check if dns entries exist
  if [[ ! -z "$config_sh" || ! -z "$resolv_conf" || ! -z "$config_dev" || ! -z "$sys_resolv_conf" || ! -z "$etc_net_sh" ]] ; then
    # If DNS entries are found, check that the server can ping them
    logger echo -e "DNS Entries found, checking for internet connection"
    ping -c 1 $dns >/dev/null 2>&1
    if [[ $? != 0 ]] ; then
      # If DNS entries are found, but not responding, 
      # remove DNS entries to prevent drivers from hanging on boot
      logger echo -e "${ong}DNS $dns is not responding to ping${dfl}"
      logger echo -e "Removing DNS entries from network configuration"
      return 1
    else
      # If DNS entries are found, but responding, leave the entries intact
      logger echo -e "${grn}DNS is responding, entries valid.${dfl}"
      logger echo -e "${lyl}Proceeding with initialization.${dfl}"
      return 0
    fi
  else
    logger echo -e "DNS Entries not found, skipping DNS pingcheck"
    return 0
  fi
}

dnspurge(){
  # Run first dns check and removal
  removedns
  # Run network reset
  sudo /sbin/service network restart
  # Run second dns check for lingering entries
  logger echo -e "${pur}Re-checking dns entries${dfl}"
  removedns
}

moxatty(){
  ls /dev/tty* | grep -c ttyr00
}

# Checks moxa's online status and stores state via external 'pingtest' file
online(){
  if [ ! -f $pingfile ] ; then
    if ping -c 1 -W 1 $@ &> /dev/null ; then
      echo 2
    else
      echo 1
    fi
  else
    if ping -c 1 -W 1 $@ &> /dev/null ; then
      echo 0
    else
      echo 3
    fi
  fi
}

# Checks moxa's online status and stores state in a variable
pingtest(){
  if [[ $moxaonline == true ]] ; then
    if ping -c 1 -W 1 $@ &> /dev/null ; then 
      echo 0
    else
      echo 3
    fi
  else
    if ping -c 1 -W 1 $@ &> /dev/null ; then
      echo 2
    else
      echo 1
    fi
  fi
}

# Launch the Moxa NPort loader application
start(){
    /usr/lib/npreal2/driver/mxloadsvr
}

# Force terminate any instances of the Moxa NPort application
stop(){
  sudo pkill -9 npreal2d
}

# Force stop of any daemonized instances of this script
fullstop(){
  stop
  sudo kill -9 $daemonpid
}

# Restart of multiple services is required to re-establish device control after
# the NPort loses its connection. The order of restarting these services is
# significant, and should be maintained.
restart(){
      stop
      start
      god restart rs232
      sudo /sbin/service SimpleHttpDeviceServer restart_noscript
      sudo /sbin/service BDVHardwareManager restart
      god restart steris_act
}

conditionalrestart(){
  if [[ $(dnscheck) == 0 ]] ; then
    stop
    start
  fi
  god restart rs232
  sudo /sbin/service SimpleHttpDeviceServer restart_noscript
  sudo /sbin/service BDVHardwareManager restart
  god restart steris_act
}

# Clears loop flag variables
clearflags(){
  moxaonline=
  pingfails=
  state=
}

#------------------------------------------------------#
# Options and Arguments Parser
#------------------------------------------------------#

case $1 in
  -s | start | --start)
    start
    exit 0
    ;;
  -S | stop | --stop)
    fullstop
    exit $?
    ;;
  -R | --force-restart)
    fullstop
    restart
    exit 0
    ;;
  -r | restart | --restart)
    conditionalrestart
    exit 0
    ;;
  -p | ping | --ping)
    online moxa
    exit $?
    ;;
  -P | pid | --pid)
    echo -e "$daemonpid"
    exit $?
    ;;
  -d | daemon | --daemon)
    start
    ;;
  -u | --usage)
    usage
    exit -1
    ;;
  -h | --help)
    usage
    exit -1
    ;;
  -v | --version)
    echo $VERSION
    exit 0
    ;;
  -F | --fix-dns)
    purgedns
    exit 0
    ;;
  *)
    warn "Invalid argument $@"
    usage
    exit -1
    ;;
esac

#-----------------------------------------------------------------#
# Process substitution to fork log output
# Only uncomment if all script output should be logged!
#-----------------------------------------------------------------#

# exec &> >(tee  $logfile)

#------------------------------------------------------#
# Script begins here
#------------------------------------------------------#

logger boxtop
logger boxline "${lbl}Moxa NPort Driver Loader v$VERSION${dfl}"
logger boxbottom

# Unset flags
clearflags

while true ; do
  state=$(online moxa)
  case $state in
    0)  # State 0 = Moxa is online, and was online in previous loop. No action needed
      boxtop
      boxline "${grn}Moxa NPort Online...${dfl}"
      boxbottom
      moxaonline=true
      ;;
    1)  # State 1 = Moxa is offline, and was offline in previous loop. No action needed
      boxtop
      boxline "${lrd}Moxa NPort Offline${dfl}"
      boxbottom
      moxaonline=false
      failpings=$((failpings+1))
      ;;
    2)  # State 2 = Moxa is online, but was offline in previous loop. Service Restart required to restore functionality and update moxaonline state
      #if [[ $rst_threshold -gt $failpings ]] ; then
        logger boxtop
        logger boxline "${grn}Moxa NPort Came Online!${dfl}"
        logger boxline "... ${lyl}Restarting Services${dfl} ..."
        logger boxbottom
        moxaonline=true
        touch $pingfile
        conditionalrestart
      #fi
      ;;
    3)  # State 3 = Moxa is offline, but was online in previous loop. Start counting failed pings, and update moxaonline state 
      logger boxtop
      logger boxline "${grn}Moxa NPort Has Gone Offline${dfl}"
      logger boxline "${lyl}Awaiting Response before Restart${dfl} ..."
      logger boxbottom
      moxaonline=false
      rm $pingfile
      failpings=1
      ;;
  esac
  boxtop
  boxline "Moxa Online = $moxaonline"
  boxline "Checking again in $ratelimit seconds..."
  boxbottom
  sleep $ratelimit
done
