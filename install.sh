#!/bin/bash
# initial vars
rundir=${0%/*}
source ${rundir}/functions
scriptname=${0##*/}
runuser=$(whoami)

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
)
globalinstalldir="/usr/lib/pyr0-bash"

#-----------------------------------------------------------------#
# Script-specific Funcitons
#-----------------------------------------------------------------#

usage(){
    boxtop
    boxline "${lyl}$scriptname - v${VERSION}:${dfl}"
    boxline "${lbl}Usage:${dfl}"
    boxline "${lyl}$scriptname ${bld}[args]"
    boxseparator
    boxline "[args:]"
    boxline "   -i [--install]"
    boxline "   -r [--remove]"
    boxline "   -u [--update]"
    boxline "   -h [--help]"
    boxbottom
}

install(){
    mkdir -p ${globalinstalldir}
    cp ${rundir}/functions ${globalinstalldir}/functions
    cp -r $rundir/lib/skel/* $HOME
    cp $rundir/lib/vimfiles/crystallite.vim /usr/share/vim/vim*/colors/crystallite.vim
    cp $rundir/lib/vimfiles/vimrc.local /etc/vim/vimrc.local
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