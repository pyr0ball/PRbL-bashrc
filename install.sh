#!/bin/bash
###################################################################
#         Pyr0ball's Reductive Bash Library Installer            #
###################################################################

# initial vars
VERSION=2.0.0
scripttitle="Pyr0ball's Reductive Bash Library Installer - v$VERSION"
rundir=${0%/*}
source ${rundir}/functions
installer_functionsrev=$functionsrev
scriptname=${0##*/}
runuser=$(whoami)
users=($(ls /home/))
userinstalldir="$HOME/.local/share/prbl"
globalinstalldir="/usr/share/prbl"

#-----------------------------------------------------------------#
# Script-specific Parameters
#-----------------------------------------------------------------#

# List of dependency packaged to be istalled via apt
packages="git
vim
lm-sensors
curl
"

# OS distribution auto-detection
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
  OS=$(cat /etc/redhat-release | awk '{print $1}')
else
  # Fall back to uname, e.g. "Linux <version>", also works for BSD, etc.
  OS=$(uname -s)
  VER=$(uname -r)
fi

# Add apt-notifier-common required packages
if [[ $OS_DETECTED == "Debian" ]] || [[ $OS_DETECTED == "Ubuntu" ]]; then
    packages="$packages
apt-config-auto-update"
fi

bashrc_append="
# Pluggable bashrc config. Add environment modifications to ~/.bashrc.d/ and append with '.bashrc'
if [ -n \"\$BASH_VERSION\" ]; then
    # include .bashrc if it exists
    if [ -d \"\$HOME/.bashrc.d\" ]; then
        for file in \$HOME/.bashrc.d/*.bashrc ; do
            source \"\$file\"
        done
    fi
fi
"

#-----------------------------------------------------------------#
# Script-specific Funcitons
#-----------------------------------------------------------------#

usage(){
    boxborder \
        "${lyl}$scripttitle${dfl}" \
        "${lbl}Usage:${dfl}" \
        "${lyl}./$scriptname ${bld}[args]${dfl}" \
        "$(boxseparator)" \
        "[args:]" \
        "   -i [--install]" \
        "   -r [--remove]" \
        "   -u [--update]" \
        "   -h [--help]" \
        "" \
        "Running this installer as 'root' will install globally to $globalinstalldir" \
        "You must run as 'root' for this script to automatically resolve dependencies"
}

detectvim(){
    if [ -d /usr/share/vim ] ; then
        viminstall=$(ls -lah /usr/share/vim/ | grep vim | grep -v rc | awk '{print $NF}')
    else
        viminstall=null
        warn "vim is not currently installed, unable to set up colorscheme and formatting"
    fi
}

check-deps(){
    for pkg in $packages ; do
        local _pkg=$(dpkg -l $pkg 2>&1 >/dev/null ; echo $?)
        if [[ $_pkg != 0 ]] ; then
            bins_missing="${bins_missing} $pkg"
        fi
    done
    local _bins_missing=$(echo $bins_missing | wc -w)
    if [[ $_bins_missing == 0 ]] ; then
        bins_missing="false"
    else
        return $bins_missing
    fi
}

install-deps(){
    boxborder "Installing packages $packages"
    spin "for $_package in $packages ; do sudo apt=get install -y $_package ; done"
    depsinstalled=true
}

install(){
    if [[ $runuser == root ]] ; then
        installdir="${globalinstalldir}"
        prbl_bashrc="# Pyr0ball's Reductive Bash Library (PRbL) Functions library v$VERSION and greeting page setup
export prbl_functions=\"${installdir}/functions\""
        globalinstall
    else
        installdir="${userinstalldir}"
        prbl_bashrc="# Pyr0ball's Reductive Bash Library (PRbL) Functions library v$VERSION and greeting page setup
export prbl_functions=\"${installdir}/functions\""
        userinstall
    fi
}

userinstall(){

    # Create install directory under user's home directory
    mkdir -p ${installdir}

    # Check if functions already exist, and check if functions are out of date
    if [ -f ${installdir}/functions ] ; then
        # if functions are out of date, remove before installing new version
        if [[ $(vercomp $(cat ${rundir/functions} | grep functionsrev ) $installer_functionsrev) == 2 ]] ; then
            rm ${installdir}/functions
        fi
    fi


    # Copy functions first
    cp ${rundir}/functions ${installdir}/functions

    # Copy bashrc scripts to home folder
    #cp -r ${rundir}/lib/skel/* $HOME/
    scp -r ${rundir}/lib/skel/.* $HOME

    # Check for dependent applications and warn user if any are missing
    check-deps
    if [[ "$bins_missing" != "false" ]] ; then
        warn "Some of the utilities needed by this script are missing"
        echo -e "Missing utilities:"
        echo -e "$bins_missing"
        echo -e "After this installer completes, run:"
        boxseparator
        echo -en "\n${lbl}sudo apt install -y $bins_missing\n${dfl}"
        boxborder "Press 'Enter' key when ready to proceed"
        read proceed
    fi

    # Check for and parse the installed vim version
    detectvim

    # If vim is installed, add config files for colorization and expandtab
    if [[ $viminstall != null ]] ; then
        mkdir -p ${HOME}/.vim/colors
        cp $rundir/lib/vimfiles/crystallite.vim ${HOME}/.vim/colors/crystallite.vim
        cp $rundir/lib/vimfiles/vimrc.local $HOME/.vimrc
    fi

    # Check for existing bashrc config, append if missing
    if [[ $(cat ${HOME}/.bashrc | grep -c 'bashrc.d') == 0 ]] ; then
        echo -e "$bashrc_append" >> $HOME/.bashrc && boxborder "bashc.d installed..." || warn "Malformed append on ${lbl}${HOME}/.bashrc${dfl}. Check this file for errors"
        echo -e "$prbl_bashrc" >> $HOME/.bashrc.d/00-prbl.bashrc && boxborder "bashc.d/00-prbl installed..." || warn "Malformed append on ${lbl}${HOME}/.bashrc.d/00-prbl.bashrc${dfl}. Check this file for errors"
    fi


    # Create the quickinfo cache directory
    mkdir -p $HOME/.quickinfo
    export prbl_functions="${installdir}/functions"

    # If all required dependencies are installed, launch initial cache creation
    #if [[ "$bins_missing" == "false" ]] ; then
    #    bash $HOME/.bashrc.d/11-quickinfo.bashrc
    #fi
    #clear

    # Download and install any other extras
    if [ -f "${rundir_absolute}/extra.installs" ] ; then
        /bin/bash ${rundir_absolute}/extra.installs
    fi

    boxborder "${grn}Please be sure to run ${lyl}sensors-detect --auto${grn} after installation completes${dfl}"
    success "\t${red}P${lrd}R${ylw}b${ong}L ${lyl}Installed!${dfl}"
}

globalinstall(){
    # Create global install directory
    mkdir -p ${globalinstalldir}

    # Copy functions
    cp ${rundir}/PRbL/functions ${globalinstalldir}/functions
    export prbl_functions="${globalinstalldir}/functions"

    # Check for dependent applications and offer to install
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
            0)  boxborder "${grn}Installing dependencies...${dfl}"
                spin "install-deps"
                ;;
            1)  warn "Dependent Utilities missing: $bins_missing" ;;
        esac
    fi

    # Prompt the user to specify which users to install the quickinfo script for
    boxborder "Which users should PRbL be installed for?"
    multiselect result users "false"

    # For each user, compare input choice and apply installs
    idx=0
    for selecteduser in "${users[@]}"; do
        # If the selected user is set to true
        if [[ "${result[idx]}" == "true" ]] ; then
            #cp -r ${rundir}/lib/skel/* /etc/skel/
            cp -r ${rundir}/lib/skel/.* /home/${selecteduser}
            if [[ $(cat /home/${selecteduser}/.bashrc | grep -c prbl) == 0 ]] ; then
                echo -e "$bashrc_append" >> /home/${selecteduser}/.bashrc && boxborder "bashc.d installed..." || warn "Malformed append on ${lbl}/home/${selecteduser}/.bashrc${dfl}. Check this file for errors"
            fi
            chown -R ${selecteduser}:${selecteduser} /home/${selecteduser}
            if [[ "$bins_missing" == "false" ]] ; then
                boxborder "Checking ${selecteduser}'s bashrc..."
                su ${selecteduser} -c /home/${selecteduser}.bashrc.d/11-quickinfo.bashrc
            fi
        fi
    done

    detectvim
    if [[ $viminstall != null ]] ; then
        cp $rundir/lib/vimfiles/crystallite.vim /usr/share/vim/${viminstall}/colors/crystallite.vim
        cp $rundir/lib/vimfiles/vimrc.local /etc/vim/vimrc.local
    fi
    if [ ! -z $(which sensors-detect) ] ; then
        sensors-detect --auto
    fi

    # Download and install any other extras
    if [ -f "${rundir_absolute}/extra.installs"] ; then
        /bin/bash ${rundir_absolute}/extra.installs
    fi
    #clear
    success " [${red}P${lrd}R${ylw}b${ong}L ${lyl}Installed${dfl}]"
}


remove(){
    if [[ $runuser == root ]] ; then
        if [ -d $globalinstalldir ] ; then
            sudo rm -rf ${globalinstalldir}
        fi
    fi
    if [ -d $userinstalldir ] ; then
        rm -rf $userinstalldir
    fi
    for file in $(pushd lib/skel/ ; find ; popd) ; do
        rm $HOME/$file 2>&1 >dev/null
        rmdir $HOME/$file 2>&1 >dev/null
    done
}


update(){
    remove
    git stash -m "$pretty_date stashing changes before update to latest"
    git fetch && git pull
    install
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
