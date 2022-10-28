#!/bin/bash
###################################################################
#         Pyr0ball's Reductive Bash Library Installer            #
###################################################################

# initial vars
VERSION=1.1
scripttitle="Pyr0ball's Reductive Bash Library Installer - v$VERSION"
rundir=${0%/*}
source ${rundir}/functions
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
net-tools
update-notifier-common
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
        if [[ $_pkg == 1 ]] ; then
            bins_missing="${bins_missing} $pkg"
        fi
    done
    local _bins_missing=$(echo $bins_missing | wc -w)
    if [[ $_bins_missing == 0 ]] ; then
        bins_missing="false"
    fi
}

install-deps(){
    sudo /bin/bash -c "apt install -y $(echo -e $packages)"
    depsinstalled=true
}

install(){
    if [[ $runuser == root ]] ; then
        installdir="${globalinstalldir}"
        bashrc_append="
# Pyr0ball's Reductive Bash Library (PRbL) Functions library v$VERSION and greeting page setup
export prbl_functions=\"${installdir}/functions\"
if [ -n \"\$BASH_VERSION\" ]; then
    # include .bashrc if it exists
    if [ -d \"\$HOME/.bashrc.d\" ]; then
        for file in \$HOME/.bashrc.d/*.bashrc ; do
            source \"\$file\"
        done
    fi
fi
"
        globalinstall
    else
        installdir="${userinstalldir}"
        bashrc_append="
# Pyr0ball's Reductive Bash Library (PRbL) Functions library v$VERSION and greeting page setup
export prbl_functions=\"${installdir}/functions\"
if [ -n \"\$BASH_VERSION\" ]; then
    # include .bashrc if it exists
    if [ -d \"\$HOME/.bashrc.d\" ]; then
        for file in \$HOME/.bashrc.d/*.bashrc ; do
            source \"\$file\"
        done
    fi
fi
"
        userinstall
    fi
}

userinstall(){
    # Create install directory under user's home directory
    mkdir -p ${userinstalldir}

    # Copy functions first
    cp ${rundir}/PRbL/functions ${userinstalldir}/functions

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
    if [[ $(cat ${HOME}/.bashrc | grep -c prbl) = 0 ]] ; then
        echo -e "$bashrc_append" >> $HOME/.bashrc && boxborder "bashc.d installed..." || warn "Malformed append on ${lbl}${HOME}/.bashrc${dfl}. Check this file for errors"
    fi

    # Check crontab for quickinfo cron task
    if [[ -z $(crontab -l | grep quickinfo) ]] ; then
        crontab -l -u $runuser | cat - ${rundir}/lib/quickinfo.cron | crontab -u $runuser - && boxborder "QuickInfo cron task created." || warn "QuickInfo cron task creation failed. Check ${lbl}crontab -e${dfl} for errors"
    fi

    # Create the quickinfo cache directory
    mkdir -p $HOME/.quickinfo
    export prbl_functions="${installdir}/functions"

    # If all required dependencies are installed, launch initial cache creation
    if [[ "$bins_missing" == "false" ]] ; then
        bash $HOME/.bashrc.d/11-quickinfo.bashrc -c
    fi
    #clear
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
            0)  until [[ $depsinstalled == true ]] ; do
                    boxborder "${grn}Installing dependencies...${dfl}"
                    spin
                    install-deps
                done
                endspin
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
            scp -r ${rundir}/lib/skel/.* /home/${selecteduser}
            if [[ $(cat /home/${selecteduser}/.bashrc | grep -c prbl) == 0 ]] ; then
                echo -e "$bashrc_append" >> /home/${selecteduser}/.bashrc && boxborder "bashc.d installed..." || warn "Malformed append on ${lbl}/home/${selecteduser}/.bashrc${dfl}. Check this file for errors"
            fi
            crontab -l -u $selecteduser | cat - ${rundir}/lib/quickinfo.cron | crontab -u $selecteduser -
            mkdir -p /home/${selecteduser}/.quickinfo
            chown -R ${selecteduser}:${selecteduser} /home/${selecteduser}
            if [[ "$bins_missing" == "false" ]] ; then
                su ${selecteduser} -c /home/${selecteduser}.bashrc.d/11-quickinfo.bashrc -c
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
    #clear
    success " [${red}P${lrd}R${ylw}b${ong}L ${lyl}Installed${dfl}]"
}


remove(){

    sudo rm -rf ${globalinstalldir}
    for file in $(pushd lib/skel/ ; find ; popd) ; do
        rm $HOME/$file 2>&1 >dev/null
        rmdir $HOME/$file 2>&1 >dev/null
    done
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
