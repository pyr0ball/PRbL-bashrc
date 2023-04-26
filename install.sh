#!/bin/bash
###################################################################
#         Pyr0ball's Reductive Bash Library Installer            #
###################################################################

# initial vars
VERSION=2.2.0
scripttitle="Pyr0ball's Reductive Bash Library Installer - v$VERSION"

# Bash expansions to get the name and location of this script when run
scriptname="${BASH_SOURCE[0]##*/}"
rundir="${BASH_SOURCE[0]%/*}"

# Source PRbL functions from installer directory
source ${rundir}/functions

#-----------------------------------------------------------------#
# Script-specific Parameters
#-----------------------------------------------------------------#

# Store functions revision in a variable to compare with if already installed
installer_functionsrev=$functionsrev

# Get and store the user currently executing this script
runuser=$(whoami)

# set up an array containing the users listed under /home/
users=($(ls /home/))

# If run as non-root, default install to user's home directory
userinstalldir="$HOME/.local/share/prbl"

# If run as root, this will be the install directory
globalinstalldir="/usr/share/prbl"

# Initialize arrays for file and dependency management
bins_missing=()
backupFiles=()
installed_files=()
installed_dirs=()

# List of dependency packaged to be istalled via apt (For Debian/Ubuntu)
packages=(git
vim
lm-sensors
curl
)

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
    packages+=(apt-config-auto-update)
fi

# This variable is what is injected into the bashrc
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

# Function for displaying the usage of this script
usage(){
    boxborder \
        "${lyl}$scripttitle${dfl}" \
        "${lbl}Usage:${dfl}" \
        "${lyl}./$scriptname ${bld}[args]${dfl}" \
        "$(boxseparator)" \
        "[args:]" \
        "   -i [--install]" \
        "   -d [--dependencies]" \
        "   -D [--dry-run]" \
        "   -r [--remove]" \
        "   -f [--force]" \
        "   -F [--force-remove]" \
        "   -u [--update]" \
        "   -h [--help]" \
        "" \
        "Running this installer as 'root' will install globally to $globalinstalldir" \
        "You must run as 'root' for this script to automatically resolve dependencies"
}

detectvim(){
    # If the vim install directory exists, check for and store the highest numerical value version installed
    if [[ -d /usr/share/vim ]] ; then
        viminstall=$(ls -lah /usr/share/vim/ | grep vim | grep -v rc | awk '{print $NF}')
    else
        viminstall=null
        warn "vim is not currently installed, unable to set up colorscheme and formatting"
    fi
}

check-deps(){
    # Iterate through the list of required packages and check if installed
    for pkg in ${packages[@]} ; do
        local _pkg=$(dpkg -l $pkg 2>&1 >/dev/null ; echo $?)
        # If not installed, add it to the list of missing bins
        if [[ $_pkg != 0 ]] ; then
            bins_missing+=($pkg)
        fi
    done
    # Count the number of entries in bins_missing
    local _bins_missing=${#bins_missing[@]}
    # If higher than 0, return a fail (1)
    if [[ $_bins_missing != 0 ]] ; then
        return 1
    else
        return 0
    fi
}

install-deps(){
    boxborder "Installing packages $packages"
    if [[ dry_run == true ]] ; then
        boxline "DryRun: spin \"for $_package in $packages ; do sudo apt=get install -y $_package ; done\""
    else
        # using a spinner function block to track installation progress
        spin "for $_package in $packages ; do sudo apt=get install -y $_package ; done"
    fi
    # Sets dependency installed flag to true
    depsinstalled=true
}

install(){
    # If script is run as root, run global install
    if [[ $runuser == root ]] ; then
        installdir="${globalinstalldir}"
        prbl_bashrc="# Pyr0ball's Reductive Bash Library (PRbL) Functions library v$VERSION and greeting page setup
export prbl_functions=\"${installdir}/functions\""
        globalinstall
    else
    # If user is non-root, run user-level install
        installdir="${userinstalldir}"
        prbl_bashrc="# Pyr0ball's Reductive Bash Library (PRbL) Functions library v$VERSION and greeting page setup
export prbl_functions=\"${installdir}/functions\""
        userinstall
    fi
}

take-backup(){
    if [[ $update_run != true ]] ; then
        if [[ $dry_run == true ]] ; then
            if [[ -e $name.bak || -L $name.bak ]] ; then
                boxline "DryRun: $name.bak backup already exists"
            else
                boxline "DryRun: cp $1 \"$name\".bak"
                backup_files+=($name)
                boxline "DryRun: $name >> $rundir/backup_files.list"
            fi
        else
            name="$1"
            if [[ -e $name.bak || -L $name.bak ]] ; then
                boxline " $name.bak backup already exists"
            else
                cp $1 "$name".bak
                backup_files+=($name)
                boxline $name >> $rundir/backup_files.list
            fi
        fi
    fi
}

restore-backup(){
	echo "${#backup_files[@]}"
	for file in "${backup_files[@]}"
	do 
		cp "$file".bak $file
		echo "$file is restored"
	done
    backup_files=()
    if [ -f $rundir/backup_files.list ] ; then
        rm $rundir/backup_files.list
    fi
}

install-file(){
    local _source="$1"
    local _destination="$2"
    installed_files+=("${_destination}/${_source##*/}")
    if [[ $update_run == true ]] ; then
        boxline "PRbL updater: added file ${_destination}/${_source##*/} to list"
    else
        if [[ $dry_run == true ]] ; then
            boxline "DryRun: cp $_source $_destination"
        else
            cp $_source $_destination && boxline "Installed ${_source##*/}" || warn "Unable to install ${_source##*/}"
        fi
        echo "${_destination}/${_source##*/}" >> $rundir/installed_files.list
    fi
}

install-dir() {
    local _source="$1"
    local _destination="$2"
    installed_dirs+=$_source
    echo "$_destination" >> $rundir/installed_dirs.list
    # Install the current directory
    if [[ $update_run == true ]] ; then
        boxline "PRbL updater: added directory ${_destination}/${_source##*/} to list"
    else
        # Loop through subdirectories
        for item in "$_source"/*; do
        if [[ -d "$item" ]]; then
            # If item is a directory, recursively install it
            install-dir "$item" "$_destination"
        else
            install-file "$item" "$_destination"
        done
        fi
    fi
}

# install-dir(){
#     local _source="$1"
#     local _destination="$2"
#     installed_dirs+=("${_destination}/${_source##*/}")
#     if [[ $update_run == true ]] ; then
#         boxline "PRbL updater: added directory ${_destination}/${_source##*/} to list"
#     else
#         if [[ $dry_run == true ]] ; then
#             boxline "DryRun: cp -r $_source $_destination" 
#         else
#             cp -r $_source $_destination && boxline "Installed ${_source##*/}" || warn "Unable to install ${_source##*/}"
#         fi
#         echo "${_destination}/${_source}" >> $rundir/installed_dirs.list
#     fi
# }

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
    install-file ${rundir}/PRbL/functions ${installdir}/functions

    # Copy bashrc scripts to home folder
    #cp -r ${rundir}/lib/skel/* $HOME/
    for file in `find ${rundir}/lib/skel/ -print` ; do
        install-file $file $HOME
    done

    # Check for dependent applications and warn user if any are missing
    if ! check-deps ; then
        warn "Some of the utilities needed by this script are missing"
        echo -e "Missing utilities:"
        echo -e "${bins_missing[@]}"
        echo -e "After this installer completes, run:"
        boxseparator
        echo -en "\n${lbl}sudo apt install -y ${bins_missing[@]}\n${dfl}"
        boxborder "Press 'Enter' key when ready to proceed"
        read proceed
    fi

    # Check for and parse the installed vim version
    detectvim

    # If vim is installed, add config files for colorization and expandtab
    if [[ $viminstall != null ]] ; then
        mkdir -p ${HOME}/.vim/colors
        install-file $rundir/lib/vimfiles/crystallite.vim ${HOME}/.vim/colors/crystallite.vim
        take-backup $HOME/.vimrc
        install-file $rundir/lib/vimfiles/vimrc.local $HOME/.vimrc
    fi

    # Check for existing bashrc config, append if missing
    if [[ $(cat ${HOME}/.bashrc | grep -c 'bashrc.d') == 0 ]] ; then
        take-backup $HOME/.bashrc
        echo -e "$bashrc_append" >> $HOME/.bashrc && boxborder "bashc.d installed..." || warn "Malformed append on ${lbl}${HOME}/.bashrc${dfl}. Check this file for errors"
        echo -e "$prbl_bashrc" >> $HOME/.bashrc.d/00-prbl.bashrc && boxborder "bashc.d/00-prbl installed..." || warn "Malformed append on ${lbl}${HOME}/.bashrc.d/00-prbl.bashrc${dfl}. Check this file for errors"
    fi


    # Create the quickinfo cache directory
    #mkdir -p $HOME/.quickinfo
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
}

globalinstall(){
    # Create global install directory
    mkdir -p ${globalinstalldir}

    # Copy functions
    install-file ${rundir}/PRbL/functions ${globalinstalldir}/functions
    export prbl_functions="${globalinstalldir}/functions"

    # Check for dependent applications and offer to install
    if ! check-deps ; then
        warn "Some of the utilities needed by this script are missing"
        echo -e "Missing utilities:"
        echo -e "${bins_missing[@]}"
        echo -e "Would you like to install them? (this will require root password)"
        utilsmissing_menu=(
        "$(boxline "${green_check} Yes")"
        "$(boxline "${red_x} No")"
        )
        case `select_opt "${utilsmissing_menu[@]}"` in
            0)  boxborder "${grn}Installing dependencies...${dfl}"
                spin $(install-deps)
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
            for file in `find ${rundir}/lib/skel/ -print | tail -n +2` ; do
                if [[ -d "$file" ]] ; then
                    install-dir $file /home/${selecteduser}
                else
                    install-file $file /home/${selecteduser}
                fi
            done
            if [[ $(cat /home/${selecteduser}/.bashrc | grep -c prbl) == 0 ]] ; then
                take-backup /home/${selecteduser}/.bashrc
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
        install-file $rundir/lib/vimfiles/crystallite.vim /usr/share/vim/${viminstall}/colors/crystallite.vim
        take-backup /etc/vim/vimrc.local
        install-file $rundir/lib/vimfiles/vimrc.local /etc/vim/vimrc.local
    fi
    if [ ! -z $(which sensors-detect) ] ; then
        sensors-detect --auto
    fi

    # Download and install any other extras
    if [ -f "${rundir_absolute}/extra.installs" ] ; then
        /bin/bash ${rundir_absolute}/extra.installs
    fi
    #clear
}


remove(){
    if [ -f $rundir/installed_files.list ] ; then
        _installed_list=($(cat $rundir/installed_files.list))
    fi
    for file in "${installed_files[@]}" ; do
        if [ -f $file ] ; then
            rm "$file"
            boxline "Removed $file"
        fi
    done
    for file in "${_installed_list[@]}" ; do
        if [ -f $file ] ; then
            rm "$file"
            boxline "Removed $file"
        fi
    done
    if [ -f $rundir/installed_files.list ] ; then
        rm $rundir/installed_files.list
    fi
    installed_files=()
    # if [ -f $rundir/backup_files.list ] ; then
    #     for file in $(cat $rundir/backup_files.list) ; do
    #         restore-backup $file
    #     done
    # fi
    restore-backup
}

remove-arbitrary(){
    update_run=true
    userinstall
    globalinstall
    update_run=
    #backup_files=()
    remove
}

update(){
    remove-arbitrary
    git stash -m "$pretty_date stashing changes before update to latest"
    git fetch && git pull --recurse-submodules
    pushd PRbL
        git pull
    popd
    install
}

dry-run-report(){
    boxborder \
    "bins_missing= ${bins_missing[@]}" \
    "backup_files= ${backup_files[@]}" \
    "installed_files= ${installed_files[@]}"
}

#------------------------------------------------------#
# Options and Arguments Parser
#------------------------------------------------------#

case $1 in
    -i | --install)
        install && success " [${red}P${lrd}R${ylw}b${ong}L ${lyl}Installed${dfl}]"
        ;;
    -r | --remove)
        remove && success " [${red}P${lrd}R${ylw}b${ong}L ${lyl}Removed${dfl}]"
        ;;
    -d | --dependencies)
        install-deps && success "${red}P${lrd}R${ylw}b${ong}L${dfl} Dependencies installed!"
        ;;
    -D | --dry-run)
        dry_run=true
        install
        dry-run-report
        success "${red}P${lrd}R${ylw}b${ong}L${dfl} Dry-Run Complete!"
        ;;
    -u | --update)
        update_run=true
        update && success " [${red}P${lrd}R${ylw}b${ong}L ${lyl}Updated${dfl}]"
        ;;
    -f | --force)
        remove-arbitrary
        install && success " [${red}P${lrd}R${ylw}b${ong}L ${lyl}Installed${dfl}]"
        ;;
    -F | --force-remove)
        remove-arbitrary && success " [${red}P${lrd}R${ylw}b${ong}L ${lyl}Force-Removed${dfl}]"
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
