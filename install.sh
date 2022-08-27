#!/bin/bash
# initial vars
VERSION=0.3
rundir=${0%/*}
source ${rundir}/pyr0-bash-functions/functions
scriptname=${0##*/}
runuser=$(whoami)
globalinstalldir="$HOME/.local/share/pyr0-bash"

#-----------------------------------------------------------------#
# Script-specific Parameters
#-----------------------------------------------------------------#

VERSION=1.0
read -r -d bashrc_append << EOF
# Pyr0ball's Bash Functions library v$VERSION and greeting page setup
export pyr0-bash-functions="\$HOME/.local/share/pyr0-bash/functions"
"if [ -n \"\$BASH_VERSION\" ]; then
    # include .bashrc if it exists
    if [ -d \"\$HOME/.bashrc.d\" ]; then
        for file in \$HOME/.bashrc.d/*.bashrc ; do
            source \"\$file\"
        done
    fi
fi"

EOF

# List of dependency packaged to be istalled via apt
packages=(
    git
    vim
    nfs-kernel-server
    nfs-common
    lm-sensors
    net-tools
    update-notifier-common
)


#-----------------------------------------------------------------#
# Script-specific Funcitons
#-----------------------------------------------------------------#

usage(){
    boxtop
    boxline "${lyl}$scriptname - v${VERSION}:${dfl}"
    boxline "${lbl}Usage:${dfl}"
    boxline "${lyl}$scriptname ${bld}[args]${dfl}"
    boxseparator
    boxline "[args:]"
    boxline "   -i [--install]"
    boxline "   -r [--remove]"
    boxline "   -u [--update]"
    boxline "   -h [--help]"
    boxbottom
}

detectvim(){
    if [ -d /usr/share/vim ] ; then
        viminstall=$(ls -lah /usr/share/vim/ | grep vim | grep -v rc | awk '{print $NF}')
    else
        viminstall=null
        boxborder "vim is not currently installed, unable to set up colorscheme and formatting"
    fi
}

check-deps(){
  for bin in $packages ; do
    local _bin=$(which $bin | grep -c "/")
    if [[ $_bin == 0 ]] ; then
      bins_missing="${bins_missing} $bin"
    fi
  done
  local _bins_missing=$(echo -e \"${bins_missing}\" | grep -c \"*\")
  if [[ $_bins_missing == 0 ]] ; then
    bins_missing="false"
  fi
}

install-deps(){
    sudo /bin/bash -c "apt install -y $packages"
}

install(){
    mkdir -p ${globalinstalldir}
    cp ${rundir}/pyr0-bash-functions/functions ${globalinstalldir}/functions
    cp -r ${rundir}/lib/skel/* $HOME
    cp -r ${rundir}/lib/skel/.* $HOME
    detectvim
    if [[ $viminstall != null ]] ; then
        cp $rundir/lib/vimfiles/crystallite.vim /usr/share/vim/${viminstall}/colors/crystallite.vim
        cp $rundir/lib/vimfiles/vimrc.local $HOME/.vimrc
    fi
    if [[ $(cat ${HOME}/.bashrc | grep -c pyr0) = 0 ]] ; then
        echo -e $bashrc_append >> $HOME/.bashrc && center "bashc.d installed..." || fail "Unable to append .bashrc"
    fi
    crontab -l -u $runuser | cat - ${rundir}/lib/quickinfo.cron | crontab -u $runuser -
    mkdir -p $HOME/.quickinfo
    bash $HOME/.bashrc.d/11-quickinfo.bashrc -c
    clear
    check-deps
    if [[ "$bins_missing" != "false" ]] ; then
        warn "Some of the utilities needed by this script are missing"
        echo -e "Missing utilities:"
        echo -e "$bins_missing"
        echo -e "Would you like to install? (this will require root password)"
        utilsmissing_menu=(
        "$(boxline "${green_check} Yes")"
        "$(boxline "${red_x} No")"
        )
        case `select_opt "${utilsmissing_menu[@]}"` in
            0)  install-deps ;;
            1)  warn "Dependent Utilities missing: $bins_missing" ;;
        esac
    fi
    boxborder "${grn}Please be sure to run ${lyl}sensors-detect --auto${grn} after installation completes"
    success "${red}P${lrd}R${ylw}b${ong}L ${lyl}Installed${dfl}"
}

remove(){
    sudo rm -rf ${globalinstalldir}
    for file in $(pushd lib/skel/ ; find ; popd) ; do
        rm $HOME/$file 2>&1 >dev/null
        rmdir $HOME/$file 2>&1 >dev/null
    done
}

install-deps(){
    if [[ $runuser == root ]] ; then
        apt install -y $packages && success "Dependencies installed successfully!" || fail "Dependency install failed"
    else
       fail "Dependency install must be run as user 'root'"
    fi
}

update(){
    pushd $rundir
    remove
    git stash -m "$pretty_date stashing changes before update to latest"
    git fetch && git pull
    install
    popd
}

#------------------------------------------------------#
# Options and Arguments Parser
#------------------------------------------------------#

case $1 in
    -i | --install)
        install
        ;;
    -r | --remove)
        remove
        ;;
    -d | --dependencies)
        install-deps
        ;;
    -u | --update)
        update
        #sleep $ratelimit
        exit 0
        ;;
    -h | --help)
        usage
        ;;
    *)
        warn "Invalid argument $@"
        usage
        #exit 2
        ;;
esac
#------------------------------------------------------#
# Script begins here
#------------------------------------------------------#
