#!/bin/bash
# initial vars
rundir=${0%/*}
source ${rundir}/pyr0-bash-functions/functions
scriptname=${0##*/}
runuser=$(whoami)
globalinstalldir="$HOME/.local/share/pyr0-bash"

#-----------------------------------------------------------------#
# Script-specific Parameters
#-----------------------------------------------------------------#

VERSION=1.0
bashrc_append="if [ -n \"$BASH_VERSION\" ]; then
    # include .bashrc if it exists
    if [ -d \"$HOME/.bashrc.d\" ]; then
        for file in $HOME/.bashrc.d/*.bashrc ; do
            source \"$file\"
        done
    fi
fi"

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
    if [ -d /usr/share/vim] ; then
        viminstall=$(ls -lah /usr/share/vim/ | grep vim | grep -v rc | awk '{print $NF}')
    else
        viminstall=null
        boxborder "vim is not currently installed, unable to set up colorscheme and formatting"
    fi
}

install(){
    mkdir -p ${globalinstalldir}
    cp ${rundir}/functions ${globalinstalldir}/functions
    cp -r $rundir/lib/skel/* $HOME
    cp -r $rundir/lib/skel/.* $HOME
    detectvim
    if [[ $viminstall != null ]] ; then
        cp $rundir/lib/vimfiles/crystallite.vim /usr/share/vim/vim80/colors/crystallite.vim
        cp $rundir/lib/vimfiles/vimrc.local /etc/vim/vimrc.local
    fi
    echo -e $bashrc_append >> $HOME/.bashrc
}

remove(){
    echo -e "\n"
}

update(){
    pushd $rundir
    remove
    git fetch && git pull
    install
    popd
}

#------------------------------------------------------#
# Options and Arguments Parser
#------------------------------------------------------#

if [[ $runuser == root ]] ; then
    case $1 in
        -i | --install)
            install
            ;;
        -r | --remove)
            remove
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
else
    fail "Must be run as user 'root'"
fi
#------------------------------------------------------#
# Script begins here
#------------------------------------------------------#
