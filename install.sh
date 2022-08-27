#!/bin/bash
# initial vars
VERSION=0.1
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
    echo -e $bashrc_append >> $HOME/.bashrc
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
