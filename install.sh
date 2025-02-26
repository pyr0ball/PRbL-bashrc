#!/bin/bash
###################################################################
#         Pyr0ball's Reductive Bash Library Installer             #
###################################################################

# Initial vars
VERSION=3.0.0
scripttitle="Pyr0ball's Reductive Bash Library Installer - v$VERSION"

# Bash expansions to get the name and location of this script when run
scriptname="${BASH_SOURCE[0]##*/}"
rundir="${BASH_SOURCE[0]%/*}"

# Source PRbL Functions locally or retrieve from online
if [ ! -z $prbl_functions ] ; then
    source $prbl_functions
else
    if [ -f ${rundir}/functions ] ; then
        source ${rundir}/functions
    else
        # Iterate through get commands and fall back on next if unavailable
        if command -v curl >/dev/null 2>&1; then
            source <(curl -ks 'https://raw.githubusercontent.com/pyr0ball/PRbL/main/functions')
        elif command -v wget >/dev/null 2>&1; then
            source <(wget -qO- 'https://raw.githubusercontent.com/pyr0ball/PRbL/main/functions')
        elif command -v fetch >/dev/null 2>&1; then
            source <(fetch -qo- 'https://raw.githubusercontent.com/pyr0ball/PRbL/main/functions')
        else
            echo "Error: curl, wget, and fetch commands are not available. Please install one to retrieve PRbL functions."
            exit 1
        fi
    fi
fi

rundir_absolute=$(pushd $rundir ; pwd ; popd)
escape_dir=$(printf %q "${rundir_absolute}")
logfile="${rundir}/${pretty_date}_${scriptname}.log"

#-----------------------------------------------------------------#
# Script-specific Parameters
#-----------------------------------------------------------------#

# Get and store the user currently executing this script
runuser=$(whoami)

# If run as non-root, default install to user's home directory
userinstalldir="$HOME/.bashrc.d"
userconfigdir="$HOME/.config/quickinfo"

# If run as root, this will be the install directory
globalinstalldir="/etc/skel/.bashrc.d"
globalconfigdir="/etc/quickinfo"

# Initialize arrays for file and dependency management
bins_missing=()
backup_files=()
installed_files=()
installed_dirs=()

# List of dependency packages to be installed
# Base package names that most distros share
packages=(
    git
    vim
    lm-sensors
    curl
    net-tools
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
elif [ -f /etc/redhat-release ]; then
    # Older Red Hat, CentOS, etc.
    OS=$(cat /etc/redhat-release | awk '{print $1}')
    VER=$(cat /etc/redhat-release | grep -o -E '[0-9]+\.[0-9]+' | head -n 1)
else
    # Fall back to uname, e.g. "Linux <version>", also works for BSD, etc.
    OS=$(uname -s)
    VER=$(uname -r)
fi

# Add distro-specific packages
case $OS in
    Debian|Ubuntu|LinuxMint)
        packages+=(smartmontools sysstat)
        ;;
    CentOS|Fedora|RHEL|Red*)
        packages+=(smartmontools sysstat)
        ;;
    Arch|Manjaro)
        packages+=(smartmontools sysstat)
        ;;
    *)
        # Default additional packages
        packages+=(smartmontools sysstat)
        ;;
esac

# This variable is what is injected into the bashrc
bashrc_append="
# Pluggable bashrc config. Add environment modifications to ~/.bashrc.d/ and append with '.bashrc'
if [ -n \"\$BASH_VERSION\" ]; then
    # include .bashrc if it exists
    if [ -d \"\$HOME/.bashrc.d\" ]; then
        for file in \$HOME/.bashrc.d/*.bashrc ; do
            if [ -f \"\$file\" ]; then
                source \"\$file\"
            fi
        done
    fi
fi
"

#-----------------------------------------------------------------#
# Script-specific Functions
#-----------------------------------------------------------------#

script-title(){
    boxborder \
    "${red}(_____ ${lrd}(_____  ${ylw}| |   ${ong}| |        ${lyl}(_____)           _        | | |            ${dfl}" \
    "${red} _____) )${lrd}____) ) ${ylw}| _ ${ong}| |        ${lyl}   _   ____   ___| |_  ____| | | ____  ____ ${dfl}" \
    "${red}|  ____${lrd}(_____ (${ylw}| ||  ${ong}| |        ${lyl}  | | |  _ \ /___)  _)/ _  | | |/ _  )/ ___)${dfl}" \
    "${red}| |          ${lrd}| ${ylw}| |_) ) ${ong}|_____   ${lyl} _| |_| | | |___ | |_( ( | | | ( (/ /| |    ${dfl}" \
    "${red}|_|          ${lrd}|_${ylw}|____/${ong}|_______)  ${lyl}(_____)_| |_(___/ \___)_||_|_|_|\____)_|    ${dfl}"
}

# Function for displaying the usage of this script
usage(){
    script-title
    boxborder \
        "${lbl}Usage:${dfl}" \
        "${lyl}./$scriptname ${bld}[args]${dfl}" \
        "$(boxseparator)" \
        "[args:]" \
        "   -i [--install]       Install QuickInfo Banner" \
        "   -d [--dependencies]  Install dependencies only" \
        "   -D [--dry-run]       Show what would be installed without making changes" \
        "   -r [--remove]        Remove QuickInfo Banner" \
        "   -u, -U [--update]    Update an existing installation" \
        "   -f [--force]         Force installation (overwrite existing files)" \
        "   -h [--help]          Show this help message" \
        "" \
        "Running this installer as 'root' will install globally to $globalinstalldir" \
        "You must run as 'root' for this script to automatically resolve dependencies"
}

check-deps(){
    # Iterate through the list of required packages and check if installed
    for pkg in ${packages[@]} ; do
        case $OS in
            Debian|Ubuntu|LinuxMint)
                local _pkg=$(dpkg -l $pkg 2>&1 >/dev/null ; echo $?)
                ;;
            CentOS|Fedora|RHEL|Red*)
                local _pkg=$(rpm -q $pkg >/dev/null 2>&1 ; echo $?)
                ;;
            Arch|Manjaro)
                local _pkg=$(pacman -Q $pkg >/dev/null 2>&1 ; echo $?)
                ;;
            *)
                # Default check method (may not work on all distros)
                local _pkg=$(which $pkg >/dev/null 2>&1 ; echo $?)
                ;;
        esac
        
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

install(){
    # If script is run as root, run global install
    if [[ $runuser == root ]] ; then
        installdir="${globalinstalldir}"
        configdir="${globalconfigdir}"
        globalinstall
    else
    # If user is non-root, run user-level install
        installdir="${userinstalldir}"
        configdir="${userconfigdir}"
        userinstall
    fi
}

install-deps(){
    boxborder "Installing packages ${bins_missing[@]}"
    if [[ dry_run != true ]] ; then
        # Install packages based on detected OS
        case $OS in
            Debian|Ubuntu|LinuxMint)
                run sudo apt-get update -y
                for _package in ${bins_missing[@]} ; do 
                    run sudo apt-get install -y $_package
                done
                ;;
            CentOS|Fedora|RHEL|Red*)
                for _package in ${bins_missing[@]} ; do 
                    run sudo yum install -y $_package
                done
                ;;
            Arch|Manjaro)
                for _package in ${bins_missing[@]} ; do 
                    run sudo pacman -Sy --noconfirm $_package
                done
                ;;
            *)
                warn "Unknown OS, cannot install dependencies automatically"
                return 1
                ;;
        esac
    else
        boxline "DryRun: Would install ${bins_missing[@]}"
    fi
    # Sets dependency installed flag to true
    depsinstalled=true
}

userinstall(){
    # Create install directory under user's home directory if it doesn't exist
    run mkdir -p ${installdir}
    run mkdir -p ${configdir}
    
    # Install config file first
    if [ ! -f ${configdir}/config ] ; then
        # Copy config file
        install-file ${rundir}/quickinfo_config.sh ${configdir}/config
        boxline "Installed configuration file to ${configdir}/config"
    else
        boxline "Config file already exists, not overwriting"
        # Create backup of existing config
        take-backup ${configdir}/config
        # Install new config as .new
        install-file ${rundir}/quickinfo_config.sh ${configdir}/config.new
        boxline "New configuration template installed to ${configdir}/config.new"
    fi
    
    # Install quickinfo script
    install-file ${rundir}/quickinfo_banner.sh ${installdir}/11-quickinfo.bashrc
    run chmod +x ${installdir}/11-quickinfo.bashrc
    boxline "Installed QuickInfo Banner script to ${installdir}/11-quickinfo.bashrc"
    
    # Check for dependent applications and warn user if any are missing
    if ! check-deps ; then
        warn "Some of the utilities needed by this script are missing"
        boxlinelog "Missing utilities:"
        boxlinelog "${bins_missing[@]}"
        boxlinelog "Would you like to install them? (this will require root password)"
        utilsmissing_menu=(
        "$(boxline "${green_check} Yes")"
        "$(boxline "${red_x} No")"
        )
        case `select_opt "${utilsmissing_menu[@]}"` in
            0)  boxlinelog "${grn}Installing dependencies...${dfl}"
                install-deps
                ;;
            1)  warn "Dependent Utilities missing: ${bins_missing[@]}" ;;
        esac
    fi
    
    # Check for existing bashrc config, append if missing
    if [[ $(grep -c 'bashrc.d' ${HOME}/.bashrc) == 0 ]] ; then
        take-backup ${HOME}/.bashrc
        echo -e "$bashrc_append" >> ${HOME}/.bashrc && boxborder "bashrc.d setup installed..." || warn "Malformed append on ${lbl}${HOME}/.bashrc${dfl}. Check this file for errors"
    fi

    # Create the quickinfo cache directory
    #mkdir -p $HOME/.quickinfo
    export prbl_functions="${installdir}/functions"

    # If all required dependencies are installed, launch initial cache creation
    #if [[ "$bins_missing" == "false" ]] ; then
    #    bash $HOME/.bashrc.d/11-quickinfo.bashrc
    #fi
    #clear

    # launch extra installs
    extras-menu

    if [[ $dry_run != true ]] ; then
        boxborder "${grn}QuickInfo Banner installed successfully${dfl}"
        boxline "You may need to log out and back in to see the banner"
    fi
}

globalinstall(){
    # Create global install directories
    run mkdir -p ${installdir}
    run mkdir -p ${configdir}
    
    # Install config file
    install-file ${rundir}/quickinfo_config.sh ${configdir}/config
    boxline "Installed global configuration file to ${configdir}/config"
    
    # Check for dependent applications and offer to install
    if ! check-deps ; then
        warn "Some of the utilities needed by this script are missing"
        boxlinelog "Missing utilities:"
        boxlinelog "${bins_missing[@]}"
        boxlinelog "Would you like to install them?"
        utilsmissing_menu=(
        "$(boxline "${green_check} Yes")"
        "$(boxline "${red_x} No")"
        )
        case `select_opt "${utilsmissing_menu[@]}"` in
            0)  boxlinelog "${grn}Installing dependencies...${dfl}"
                install-deps
                ;;
            1)  warn "Dependent Utilities missing: ${bins_missing[@]}" ;;
        esac
    fi
    
    # Prompt the user to specify which users to install the quickinfo script for
    users=($(ls /home/))
    boxborder "Which users should QuickInfo Banner be installed for?"
    multiselect result users "false"
    
    # For each user, compare input choice and apply installs
    idx=0
    for selecteduser in "${users[@]}"; do
        # If the selected user is set to true
        if [[ "${result[idx]}" == "true" ]] ; then
            # Create user's bashrc.d directory if it doesn't exist
            run mkdir -p /home/${selecteduser}/.bashrc.d
            run mkdir -p /home/${selecteduser}/.config/quickinfo
            
            # Install quickinfo script for the user
            install-file ${rundir}/quickinfo_banner.sh /home/${selecteduser}/.bashrc.d/11-quickinfo.bashrc
            run chmod +x /home/${selecteduser}/.bashrc.d/11-quickinfo.bashrc
            
            # Copy config file if it doesn't exist
            if [ ! -f /home/${selecteduser}/.config/quickinfo/config ] ; then
                install-file ${rundir}/quickinfo_config.sh /home/${selecteduser}/.config/quickinfo/config
            fi
            
            # Update .bashrc if needed
            if [[ $(grep -c 'bashrc.d' /home/${selecteduser}/.bashrc) == 0 ]] ; then
                take-backup /home/${selecteduser}/.bashrc
                echo -e "$bashrc_append" >> /home/${selecteduser}/.bashrc
            fi
            
            # Set ownership
            run chown -R ${selecteduser}:${selecteduser} /home/${selecteduser}/.bashrc.d
            run chown -R ${selecteduser}:${selecteduser} /home/${selecteduser}/.config/quickinfo
            
            boxline "Installed QuickInfo Banner for user: ${selecteduser}"
        fi
        ((idx++))
    done
    
    # Also install to /etc/skel for new users
    install-file ${rundir}/quickinfo_banner.sh ${globalinstalldir}/11-quickinfo.bashrc
    run chmod +x ${globalinstalldir}/11-quickinfo.bashrc
    boxline "Installed QuickInfo Banner to ${globalinstalldir} for new users"
    
    if [ ! -d /etc/skel/.config/quickinfo ] ; then
        run mkdir -p /etc/skel/.config/quickinfo
        install-file ${rundir}/quickinfo_config.sh /etc/skel/.config/quickinfo/config
        boxline "Installed QuickInfo Banner config to /etc/skel/.config/quickinfo for new users"
    fi
    
    # Check if /etc/skel/.bashrc exists and has bashrc.d setup
    if [ -f /etc/skel/.bashrc ] && [[ $(grep -c 'bashrc.d' /etc/skel/.bashrc) == 0 ]] ; then
        take-backup /etc/skel/.bashrc
        echo -e "$bashrc_append" >> /etc/skel/.bashrc
        boxline "Updated /etc/skel/.bashrc for new users"
    fi
    
    # Try to run sensors-detect if available
    if command -v sensors-detect >/dev/null 2>&1 ; then
        run sensors-detect --auto
    fi
    
    if [[ $dry_run != true ]] ; then
        boxborder "${grn}QuickInfo Banner installed globally${dfl}"
        boxline "Users will see the banner on their next login"
    fi
}

remove(){
    if [ -f $rundir/installed_files.list ] ; then
        _installed_list=($(cat $rundir/installed_files.list))
    fi
    for file in "${installed_files[@]}" ; do
        if [ -f $file ] ; then
            run rm "$file"
            boxline "Removed $file"
        fi
    done
    for file in "${_installed_list[@]}" ; do
        if [ -f $file ] ; then
            run rm "$file"
            boxline "Removed $file"
        fi
    done
    if [ -f $rundir/installed_files.list ] ; then
        run rm $rundir/installed_files.list
    fi
    installed_files=()
    
    restore-backup
}

uninstall() {
    # If script is run as root, run global uninstall
    if [[ $runuser == root ]] ; then
        # Prompt the user to specify which users to remove quickinfo from
        users=($(ls /home/))
        boxborder "Remove QuickInfo Banner for which users?"
        multiselect result users "false"
        
        # For each user, compare input choice and remove installs
        idx=0
        for selecteduser in "${users[@]}"; do
            # If the selected user is set to true
            if [[ "${result[idx]}" == "true" ]] ; then
                if [ -f /home/${selecteduser}/.bashrc.d/11-quickinfo.bashrc ] ; then
                    run rm /home/${selecteduser}/.bashrc.d/11-quickinfo.bashrc
                    boxline "Removed QuickInfo Banner for user: ${selecteduser}"
                fi
            fi
            ((idx++))
        done
        
        # Remove from /etc/skel
        if [ -f ${globalinstalldir}/11-quickinfo.bashrc ] ; then
            run rm ${globalinstalldir}/11-quickinfo.bashrc
            boxline "Removed QuickInfo Banner from ${globalinstalldir}"
        fi
        
        # Ask if global config should be removed
        boxborder "Remove global configuration directory at ${globalconfigdir}?"
        config_menu=(
        "$(boxline "${green_check} Yes")"
        "$(boxline "${red_x} No")"
        )
        case `select_opt "${config_menu[@]}"` in
            0)  run rm -rf ${globalconfigdir}
                boxline "Removed global configuration directory"
                ;;
            1)  boxline "Kept global configuration directory" ;;
        esac
    else
        # Remove user installation
        if [ -f ${userinstalldir}/11-quickinfo.bashrc ] ; then
            run rm ${userinstalldir}/11-quickinfo.bashrc
            boxline "Removed QuickInfo Banner from ${userinstalldir}"
        fi
        
        # Ask if user config should be removed
        boxborder "Remove configuration directory at ${userconfigdir}?"
        config_menu=(
        "$(boxline "${green_check} Yes")"
        "$(boxline "${red_x} No")"
        )
        case `select_opt "${config_menu[@]}"` in
            0)  run rm -rf ${userconfigdir}
                boxline "Removed configuration directory"
                ;;
            1)  boxline "Kept configuration directory" ;;
        esac
    fi
    
    boxborder "${grn}QuickInfo Banner has been uninstalled${dfl}"
}

update(){
    boxborder "Updating QuickInfo Banner from repository"
    
    # Check if we're in a git repository
    if [ -d "${rundir}/.git" ]; then
        boxline "Detected git repository, pulling latest changes..."
        run git -C "${rundir}" stash -m "Auto-stash before update $(date)" || true
        run git -C "${rundir}" pull
        boxline "Repository updated successfully"
    else
        boxline "Not a git repository or .git directory not found"
        boxline "Continuing with update using local files"
    fi
    
    # First uninstall old version
    if [[ $runuser == root ]] ; then
        # For global update, we need to gather installation info first
        users=($(ls /home/))
        user_has_quickinfo=()
        
        # Check which users have quickinfo installed
        for user in "${users[@]}"; do
            if [ -f /home/${user}/.bashrc.d/11-quickinfo.bashrc ] ; then
                user_has_quickinfo+=("$user")
            fi
        done
        
        # If installed in /etc/skel, note that
        has_skel_install=false
        if [ -f ${globalinstalldir}/11-quickinfo.bashrc ] ; then
            has_skel_install=true
        fi
        
        # Backup old installations before removing
        for user in "${user_has_quickinfo[@]}"; do
            if [ -f /home/${user}/.bashrc.d/11-quickinfo.bashrc ]; then
                take-backup /home/${user}/.bashrc.d/11-quickinfo.bashrc
                run rm /home/${user}/.bashrc.d/11-quickinfo.bashrc
            fi
        done
        
        if [ "$has_skel_install" = true ] ; then
            take-backup ${globalinstalldir}/11-quickinfo.bashrc
            run rm ${globalinstalldir}/11-quickinfo.bashrc
        fi
        
        # Install new version
        # For users
        for user in "${user_has_quickinfo[@]}"; do
            install-file ${rundir}/quickinfo_banner.sh /home/${user}/.bashrc.d/11-quickinfo.bashrc
            run chmod +x /home/${user}/.bashrc.d/11-quickinfo.bashrc
            run chown ${user}:${user} /home/${user}/.bashrc.d/11-quickinfo.bashrc
            
            # Update config file if needed
            if [ -f /home/${user}/.config/quickinfo/config ]; then
                # Save a backup of the current config
                take-backup /home/${user}/.config/quickinfo/config
                # Install the new config template as config.new
                run mkdir -p /home/${user}/.config/quickinfo
                install-file ${rundir}/quickinfo_config.sh /home/${user}/.config/quickinfo/config.new
                run chown ${user}:${user} /home/${user}/.config/quickinfo/config.new
                boxline "Updated config template for user: ${user} (stored as config.new)"
            fi
            
            boxline "Updated QuickInfo Banner for user: ${user}"
        done
        
        # For /etc/skel if needed
        if [ "$has_skel_install" = true ] ; then
            install-file ${rundir}/quickinfo_banner.sh ${globalinstalldir}/11-quickinfo.bashrc
            run chmod +x ${globalinstalldir}/11-quickinfo.bashrc
            
            # Update /etc/skel config
            if [ -d /etc/skel/.config/quickinfo ]; then
                install-file ${rundir}/quickinfo_config.sh /etc/skel/.config/quickinfo/config.new
                boxline "Updated config template in /etc/skel/.config/quickinfo"
            else
                run mkdir -p /etc/skel/.config/quickinfo
                install-file ${rundir}/quickinfo_config.sh /etc/skel/.config/quickinfo/config
                boxline "Created config in /etc/skel/.config/quickinfo"
            fi
            
            boxline "Updated QuickInfo Banner in ${globalinstalldir}"
        fi
        
        # Update global config
        if [ -d ${globalconfigdir} ]; then
            take-backup ${globalconfigdir}/config
            install-file ${rundir}/quickinfo_config.sh ${globalconfigdir}/config.new
            boxline "Updated global config template (stored as config.new)"
        else
            run mkdir -p ${globalconfigdir}
            install-file ${rundir}/quickinfo_config.sh ${globalconfigdir}/config
            boxline "Created global config in ${globalconfigdir}"
        fi
        
    else
        # User update is simpler
        if [ -f ${userinstalldir}/11-quickinfo.bashrc ] ; then
            take-backup ${userinstalldir}/11-quickinfo.bashrc
            run rm ${userinstalldir}/11-quickinfo.bashrc
            install-file ${rundir}/quickinfo_banner.sh ${userinstalldir}/11-quickinfo.bashrc
            run chmod +x ${userinstalldir}/11-quickinfo.bashrc
            boxline "Updated QuickInfo Banner in ${userinstalldir}"
            
            # Update config file if needed
            if [ -f ${configdir}/config ]; then
                # Save a backup of the current config
                take-backup ${configdir}/config
                # Install the new config template as config.new
                run mkdir -p ${configdir}
                install-file ${rundir}/quickinfo_config.sh ${configdir}/config.new
                boxline "Updated config template (stored as config.new)"
            else
                run mkdir -p ${configdir}
                install-file ${rundir}/quickinfo_config.sh ${configdir}/config
                boxline "Created new config in ${configdir}"
            fi
        else
            warn "QuickInfo Banner not found in ${userinstalldir}"
            boxborder "Would you like to install QuickInfo Banner?"
            install_menu=(
            "$(boxline "${green_check} Yes")"
            "$(boxline "${red_x} No")"
            )
            case `select_opt "${install_menu[@]}"` in
                0)  install
                    return $?
                    ;;
                1)  boxline "Update aborted" 
                    return 1
                    ;;
            esac
        fi
    fi
    
    boxborder "${grn}QuickInfo Banner has been updated${dfl}"
    boxline "New configuration options are available in config.new files"
    boxline "Review and merge these changes with your existing configuration"
}

dry-run-report(){
    box-rounded
    boxborder "${grn}Dry-run Report:${dfl}"
    box-norm
    boxborder \
    "bins_missing= " \
    "${bins_missing[@]}" \
    "backup_files= " \
    "${backup_files[@]}" \
    "installed_files= " \
    "${installed_files[@]}" \
    "installed_dirs= " \
    "${installed_dirs[@]}"
}

#------------------------------------------------------#
# Options and Arguments Parser
#------------------------------------------------------#
script-title
case $1 in
    -i | --install)
        install && success " [QuickInfo Banner Installed]"
        ;;
    -r | --remove)
        uninstall && success " [QuickInfo Banner Removed]"
        ;;
    -d | --dependencies)
        check-deps
        install-deps && success "Dependencies installed!"
        ;;
    -D | --dry-run)
        export dry_run=true
        box-double
        boxtop
        install
        boxbottom
        dry-run-report
        usage   
        unset dry_run
        success "Dry-Run Complete!"
        ;;
    -u | --update | -U)
        update && success " [QuickInfo Banner Updated]"
        ;;
    -f | --force)
        run rm -f ${userinstalldir}/11-quickinfo.bashrc 
        run rm -f ${globalinstalldir}/11-quickinfo.bashrc
        install && success " [QuickInfo Banner Force-Installed]"
        ;;
    -h | --help)
        usage
        ;;
    *)
        warn "Invalid argument $@"
        usage
        ;;
esac