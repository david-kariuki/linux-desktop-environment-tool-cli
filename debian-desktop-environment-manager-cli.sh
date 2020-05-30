#!/bin/bash

# Common code & words docs
# dksay - Custom function to create a custom coloured print
# |& tee -a $logFileName - append output stream to logs and output to terminal
declare -r scriptVersion="3.2" # Stores scripts version
declare -i setupCancelled=0 # Stores value to indicate setup cancellation
declare -l currentDesktopEnvironment="" # Stores the value of the current installed desktop environment
declare -l installedGNOME=0 # Stores true or false in integer if GNOME Desktop was installed
declare -l installedKDEPLASMA=0 # Stores true or false in integer if KDE PLASMA Desktop Desktop was installed
declare -l installedXFCE=0 # Stores true or false in integer if XFCE Desktop was installed
declare -l installedLXDE=0 # Stores true or false in integer if LXDE Desktop was installed
declare -l installedLXQT=0 # Stores true or false in integer if LXQT Desktop was installed
declare -l installedCINNAMON=0 # Stores true or false in integer if CINNAMON Desktop Desktop was installed
declare -l installedMATE=0 # Stores true or false in integer if MATE Desktop was installed
declare -l installedBUDGIE=0 # Stores true or false in integer if BUDGIE Desktop was installed
declare -l installedENLIGHTENMENT=0 # Stores true or false in integer if ENLIGHTENMENT Desktop was installed
declare -l installedKODI=0 # Stores true or false in integer if ENLIGHTENMENT Desktop was installed
declare -i installedAllEnvironments=0 # Strores true or false as integer if all desktop environments were installed
declare -i XServerInstalled=0 # Strores true or false as integer if XServer is installed
declare -i -r numberOfDesktopEnvironments=9 # Stores total number of desktop environments
declare -l -r scriptName="debian-desktop-environment-manager-cli" # Stores script file name (Set to lowers and read-only)
declare -l -r logFileName="$scriptName-logs.txt" # Stores script log-file name (Set to lowers and read-only)
declare -l -r networkTestUrl="www.google.com" # Stores the networkTestUrl (Set to lowers and read-only)

# Function to create a custom coloured print
function dksay(){
    RED="\033[0;31m"    # 31 - red    : "\e[1;31m$1\e[0m"
    GREEN="\033[0;32m"  # 32 - green  : "\e[1;32m$1\e[0m"
    YELLOW="\033[1;33m" # 33 - yellow : "\e[1;33m$1\e[0m"
    BLUE="\033[1;34m"   # 34 - blue   : "\e[1;34m$1\e[0m"
    PURPLE="\033[1;35m" # 35 - purple : "\e[1;35m$1\e[0m"
    NC="\033[0m"        # No Color    : "\e[0m$1\e[0m"
    printf "\e[48;5;0m${!1}${2} ${NC}\n" # Display coloured text setting its background color to black
}

# Function to space out different sections
function sectionBreak(){
    dksay "NC" "......\n\n" |& tee -a $logFileName # Print without color3
}

# Function to show connection established message
function connEst(){
    dksay "GREEN" "\n Internet connection established!!\n" |& tee -a $logFileName
}

# Function to show connection failed message
function connFailed(){
    dksay "RED" "\n Internet connection failed!!\n" |& tee -a $logFileName
}

# Function to initiate logfile
function initLogFile(){
    cd ~ || exit # Change directory to users' home directory
    rm -f $logFileName # Delete log file if/not it exists to prevent append to previous logs
    touch $logFileName # Creating log file
    currentDate="\n Date : `date` \n\n\n" # Get current date
    printf $currentDate &>> $logFileName # Log date without showing on terminal

    # Change to users' home directory to prevent installing some packages to unknown user directories
    dksay "YELLOW" "\n\n Changed directory to home directory." |& tee -a $logFileName
    sleep 3s # Hold for user to read
    dksay "YELLOW" "\n Created log file in $(pwd) named \e[1;32m$logFileName\e[0m\n" |& tee -a $logFileName
    sleep 4s # Hold for user to read
    sectionBreak
}

# Function to check for internet connection and validate security on connection
function isConnected(){
    # Creating integer variable
    declare -i count=0 # Declare loop count variable
    declare -i -r retrNum=4 # Declare and set number of retries to read-only
    declare -i -r maxRetr=$[retrNum + 1] # Declare and set max retry to read-only
    declare -i -r countDownTime=30 # Declare and set retry to read-only

    while :
    do # Starting infinite loop
        dksay "YELLOW" "\n\n Checking for internet connection!!" |& tee -a $logFileName
        if nc -zw1 $networkTestUrl 443 && echo |openssl s_client -connect $networkTestUrl:443 2>&1 |awk '
            handshake && $1 == "Verification" { if ($2=="OK") exit; exit 1 }
	          $1 $2 == "SSLhandshake" { handshake = 1 }';
        then # Internet connection established
            connEst # Display internet connection established message
            return $(true) # Exit loop returning true
        else # Internet connection failed
            connFailed # Display internet connection failed message

            if [ "$count" == 0 ]; then
                dksay "YELLOW" "\n Attemting re-connection...\n Max number of retries : \e[0m$maxRetr\e[0m\n" |& tee -a $logFileName
            fi
            # Check for max number of retries
            if [ "$count" -gt "$retrNum" ]; then
                dksay "YELLOW" "\n Number of retries: $count" |& tee -a $logFileName # Display number of retries
                return $(false) # Exit loop returning false
            else
                count=$[count + 1] # Increment loop counter variable

                # Run countdown
                date1=$((`date +%s` + $countDownTime));
                while [ "$date1" -ge "$(date +%s)" ]; do
                  echo -ne " \e[1;32mRetrying connection after :\e[0m \e[1;33m$(date -u --date @$(($date1 - `date +%s`)) +%H:%M:%S)\r\e[0m" |& tee -a $logFileName
                  sleep 0.1
                done
            fi
        fi
        sleep 1 # Hold loop
    done
}


# Function to log scripts' changelogs
function logChangeLogs(){
    dksay "YELLOW"  "\n\n Logging ChangeLogs." |& tee -a $logFileName # Log while showing on terminal
    dksay "RED"     "\n $scriptName ChangeLogs." &>> $logFileName # Log without showing on terminal
    dksay "GREEN"   "\n Version 1.0:" &>> $logFileName # Log without showing on terminal
    dksay "YELLOW"  "\n\t 1. Added options to install:" &>> $logFileName # Log without showing on terminal
    dksay "NC" "
        \n\t\t a. GNOME Desktop environment.
        \n\t\t b. KDE PLASMA Desktop environment.
        \n\t\t c. XFCE Desktop environment.
        \n\t\t d. LXDE Desktop environment.
        \n\t\t e. LXQT Desktop environment.
        \n\t\t f. CINNAMON Desktop environment.
        \n\t\t g. MATE Desktop environment. " &>> $logFileName # Log without showing on terminal
    sleep 1s # Hold for user to read
    dksay "GREEN"   "\n Version 1.1:" &>> $logFileName # Log without showing on terminal
    dksay "NC" "
        \n\t\t a. Added function to setup, enable and start desktop environment automatically after installation of a desktop environment\n\t\t    for users who initially, did not have any desktop environment installed."  &>> $logFileName # Log without showing on terminal
    sleep 1s # Hold for user to read
    dksay "GREEN"   "\n Version 1.2:" &>> $logFileName # Log without showing on terminal
    dksay "NC" "
        \n\t\t a. Changed KDE installation from standard installation to full installation.
        \n\t\t b. Fixed some bugs including one that made installing all desktop environments a problem." &>> $logFileName # Log without showing on terminal
    sleep 1s # Hold for user to read
    dksay "GREEN"   "\n Version 2.0:" &>> $logFileName # Log without showing on terminal
    dksay "YELLOW"  "\n\t 1. Added options to install:" &>> $logFileName # Log without showing on terminal
    dksay "NC" "
        \n\t\t a. BUDGIE Desktop environment.
        \n\t\t b. ENLIGHTENMENT Desktop environment." &>> $logFileName # Log without showing on terminal
    sleep 1s # Hold for user to read
    dksay "GREEN"   "\n Version 3.0:" &>> $logFileName # Log without showing on terminal
    dksay "YELLOW"  "\n\t 1. Added options to install:" &>> $logFileName # Log without showing on terminal
    dksay "NC" "
        \n\t\t a. KODI Desktop environment."&>> $logFileName # Log without showing on terminal
    sleep 1s # Hold for user to read
    dksay "GREEN"   "\n Version 3.1:" &>> $logFileName # Log without showing on terminal
    dksay "NC" "
        \n\t\t a. Added feature to install X Window Server.
        \n\t\t b. Logs feature bug fixes.
        \n\t\t c. Changed name from debian-install-desktop-environment-cli.sh to debian-desktop-environment-manager-cli.sh " &>> $logFileName # Log without showing on terminal
    sleep 1s # Hold for user to read
    dksay "GREEN"   "\n Version 3.2:" &>> $logFileName # Log without showing on terminal
    dksay "NC" "
        \n\t\t a. Added feature to install missing desktop environments base packages and some extras.
        \n\t\t b. Logs feature bug fixes. " &>> $logFileName # Log without showing on terminal
    sleep 1s # Hold for user to read

    dksay "GREEN" "\n ChangeLogs logging completed."
    sectionBreak
}

# Function to update system packages, upgrade software packages and update apt-file
function updateAndUpgrade(){
    # Checking for connection after every major sep incase of network failure during one stage
    if isConnected; then # Checking for internet connection
        # Internet connection established
        dksay "YELLOW" "\n Updating system packages." |& tee -a $logFileName
        sleep 3s # Hold for user to read
        apt-get update |& tee -a $logFileName
        sectionBreak
    else apt-get check; apt-get --fix-broken install; dpkg --configure -a; apt-get autoremove; apt-get autoclean;apt-get clean; appstreamcli refresh --force; apt-file update; sectionBreak
    fi
    if isConnected; then # Checking for internet connection
        # Internet connection established
        dksay "YELLOW" "\n Upgrading software packages." |& tee -a $logFileName
        sleep 3s # Hold for user to read
        apt-get upgrade -y |& tee -a $logFileName
        sectionBreak
    else apt-get check; apt-get --fix-broken install; dpkg --configure -a; apt-get autoremove; apt-get autoclean;apt-get clean; appstreamcli refresh --force; apt-file update; sectionBreak
    fi
    if isConnected; then # Checking for internet connection
        # Internet connection established
        dksay "YELLOW" "\n Running dist upgrade." |& tee -a $logFileName
        sleep 3s # Hold for user to read
        apt-get dist-upgrade -y |& tee -a $logFileName
        sectionBreak
    else apt-get check; apt-get --fix-broken install; dpkg --configure -a; apt-get autoremove; apt-get autoclean;apt-get clean; appstreamcli refresh --force; apt-file update; sectionBreak
    fi
    if isConnected; then # Checking for internet connection
        # Internet connection established
        dksay "YELLOW" "\n Running full upgrade." |& tee -a $logFileName
        sleep 3s # Hold for user to read
        apt-get full-upgrade -y |& tee -a $logFileName
        sectionBreak
    else apt-get check; apt-get --fix-broken install; dpkg --configure -a; apt-get autoremove; apt-get autoclean;apt-get clean; appstreamcli refresh --force; apt-file update; sectionBreak
    fi
    if isConnected; then # Checking for internet connection
        # Internet connection established
        dksay "YELLOW" "\n Installing apt-file for apt-file updates." |& tee -a $logFileName
        sleep 3s # Hold for user to read
        apt-get install apt-file -y |& tee -a $logFileName
        sectionBreak
        dksay "YELLOW" "\n Running apt-file update." |& tee -a $logFileName
        sleep 3s
        apt-file update |& tee -a $logFileName
        sectionBreak
    else apt-get check; apt-get --fix-broken install; dpkg --configure -a; apt-get autoremove; apt-get autoclean;apt-get clean; appstreamcli refresh --force; apt-file update; sectionBreak
    fi
}

# Function to fix any unmet dependencies and broken installs incase of network interruption
function checkDebugAndRollback(){
    if [ "$1" == '--debug' ]; then # Check for debug switch
        dksay "YELLOW" "\n Checking for errors and debugging. Please wait..." |& tee -a $logFileName
    elif [ "$1" == '--network' ]; then # Check for network switch
        dksay "GREEN" "\n Debugging and rolling back some changes due to network interrupt. Please wait..." |& tee -a $logFileName
    fi
    sleep 3s # Hold for user to read

    dksay "YELLOW"  "\n Checking for broken/unmet dependencies and fixing broken installs." |& tee -a $logFileName
    sleep 3s # Hold for user to read
    apt-get check |& tee -a $logFileName
    apt-get --fix-broken install |& tee -a $logFileName
    sectionBreak
    dksay "YELLOW" "\n Cleaning apt-get cache, disk space and removing unused packages." |& tee -a $logFileName
    sleep 3s # Hold for user to read
    apt-get autoclean |& tee -a $logFileName
    apt-get clean |& tee -a $logFileName
    apt-get autoremove |& tee -a $logFileName
    sectionBreak
    dksay "YELLOW" "\n Configuring packages." |& tee -a $logFileName
    sleep 3s # Hold for user to read
    dpkg --configure -a |& tee -a $logFileName
    sectionBreak

    if [[ "$2" == '--update-upgrade' && "$1" == '--debug' ]]; then # Check for update-upgrade switch
        updateAndUpgrade # Update system packages and upgrade software packages
    fi

    dksay "YELLOW" "\n Cleaning apt-get cache, disk space and removing unused packages." |& tee -a $logFileName
    sleep 3s # Hold for user to read
    apt-get autoclean |& tee -a $logFileName
    apt-get clean |& tee -a $logFileName
    apt-get autoremove |& tee -a $logFileName
    sectionBreak
    dksay "YELLOW" "\n Updating AppStream cache." |& tee -a $logFileName
    sleep 3s # Hold for user to read
    appstreamcli refresh --force |& tee -a $logFileName
    sectionBreak
    dksay "GREEN" "\n Checking and debugging completed successfuly!!" |& tee -a $logFileName
    sectionBreak
}

# Function to exit script with custom coloured message
function exitScript(){
    dksay "RED" "\n\n Exiting script....\n\n" |& tee -a $logFileName # Display exit message
    sleep 3s # Hold for user to read

    if [ "$1" == '--end' ]; then # Check for --end switch
        if [ "$setupCancelled" -eq 0 ]; then
            # Check and debug any errors
            checkDebugAndRollback --debug --update-upgrade
        fi

        dksay "YELLOW" "\n Adding scripts\' ChangeLogs to logs"
        logChangeLogs # Log ChangeLogs without showing on terminal

        cd ~ || exit # Change to home directory
        dksay "YELLOW" "\n You can find this scripts\' logs in \e[1;31m$(pwd)\e[0m named $logFileName"
        sleep 1s # Hold for user to read
        dksay "GREEN" "\n\n Type: \e[1;31mcat $scriptName\e[0m to view the logs in terminal"

        # Draw logo
        dksay "GREEN" "\n\n       __   __\n      |  | |  |  ___\n      |  | |  | /  /\n    __|  | |  |/  /\n  /  _   | |     <\n |  (_|  | |  |\  \ \n  \______| |__| \__\ \n\n "
    elif [ "$1" == '--connectionFailure' ]; then
      dksay "RED"   "\n\n This script requires a stable internet connection to work fully!!" |& tee -a $logFileName
      dksay "NC" "\n Please check your connection settings and re-run the script.\n" |& tee -a $logFileName
      sleep 1s # Hold for user to read

      if [ "$2" == '--rollback' ]; then # Check for rollback switch
          # Initiate debug and rollback
          checkDebugAndRollback --network # Check for and fix any broken installs or unmet dependencies
      fi
      dksay "YELLOW" "\n Please re-run script when there is a stable internet connection." |& tee -a $logFileName
      sleep 1s # Hold for user to read
    fi
    exit 0 # Exit script
}

# Function to check current desktop environment
function checkForDesktopEnvironment(){
    dksay "YELLOW" "\n Checking for desktop environment.." |& tee -a $logFileName
    sleep 3s # Hold for user to read
    if [ "$XDG_CURRENT_DESKTOP" = "" ]; then # Check for current desktop environment
        # Check for installed  Desktop environments
        currentDesktopEnvironment=$(echo "$XDG_DATA_DIRS" | sed 's/.*\(gnome\|kde\|xfce\|lxde\|lxqt\|cinnamon\|mate\|budgie\|enlightenment\|kodi\).*/\1/')
    else currentDesktopEnvironment=$XDG_CURRENT_DESKTOP # Get XDG current desktop
    fi
    # Check if desktop environment was found
    if [ -z "$currentDesktopEnvironment" ]; then # (Variable empty) - Desktop environment not found
        dksay "GREEN" "\n No desktop environment found!!" |& tee -a $logFileName
    else dksay "GREEN" "\n Current default desktop environment : $currentDesktopEnvironment" |& tee -a $logFileName # Display choice
    fi
}

# Function to check the set default desktop environment incase of more that one desktop environment
function checkSetDefaultDesktopEnvironment(){
    dksay "YELLOW" "\n Checking for the default desktop environment." |& tee -a $logFileName
    sleep 2s # Hold for user to read
    cat /etc/X11/default-display-manager |& tee -a $logFileName # Display set default desktop environment
}

# Function to query if user wants to install another desktop environment after installing the previous
function queryInstallAnotherDesktopEnvironment(){
    while true; do # Start infinite loop
        # Prompt user to set GNOME Desktop as default
        dksay "YELLOW" "\n Would you like to install another desktop environment?\n\t1. Y (Yes) - to install another.\n\t2. N (No) to cancel." |& tee -a $logFileName
        read -p ' option: ' queryInstChoice
        queryInstChoice=${queryInstChoice,,} # Convert to lowercase
        dksay "GREEN" " You chose : $queryInstChoice" |& tee -a $logFileName # Display choice

        if  [[ "$queryInstChoice" == 'yes' || "$queryInstChoice" == 'y' || "$queryInstChoice" == '1' ]]; then # Option : Yes
            return $(true) # Exit loop returning true
        elif [[ "$queryInstChoice" == 'no' || "$queryInstChoice" == 'n' || "$queryInstChoice" == '2' ]]; then # Option : No
            return $(false) # Exit loop returning false
        else dksay "GREEN" "\n Invalid entry!! Please try again." |& tee -a $logFileName # Invalid entry
        fi
        sleep 1 # Hold loop
    done
}

# Function to install X Window Server (xorg)
function installXWindowServer(){
    # Check if XServer is installed
    check=`dpkg -l |grep xserver-xorg-core`

    # Check for command outp.ut
    if [[ "$check" == *"ii  xserver-xorg-core"* || "$check" == *"Xorg X server - core server"* ]]; then # XServer found
        if [ $XServerInstalled -eq 0 ]; then # To display below message only once during runtime
            dksay "GREEN" "\n Checked for XServer installation.\n ...XServer is already installed."
            XServerInstalled=1 # Set X Server installed to true.
            sleep 4s # Hold for user to read
        fi
    else # XServer not found
        # Checking for internet connection before continuing
        if isConnected; then # Internet connection Established
            dksay "YELLOW" "\n\n Installing XORG. This may take a while depending on your internet connection. Please wait..." |& tee -a $logFileName
            sleep 6s # Hold for user to read
            apt-get install xorg -y |& tee -a $logFileName # # Install X window Server
            sectionBreak
        else exitScript --connectionFailure # Exit script on connection failure
        fi
    fi
}

# Function to install GNOME Desktop environment
function installGNOMEDesktop(){
    # Install X Window Server
    installXWindowServer

    # Checking for internet connection before continuing
    if isConnected; then # Internet connection Established
        dksay "YELLOW" "\n\n Installing GNOME. This may take a while depending on your internet connection. Please wait..." |& tee -a $logFileName
        sleep 6s # Hold for user to read
        if [ "$1" == '--y' ]; then # Check for yes switch to install without confirmation
            apt-get install gnome task-gnome-desktop -y |& tee -a $logFileName # Install full GNOME with confirmation
        else apt-get install gnome task-gnome-desktop |& tee -a $logFileName # Install full GNOME without confirmation
        fi
        dksay "YELLOW" "\n\n Installing alacarte - Alacarte is a menu editor for the GNOME Desktop, written in Python" |& tee -a $logFileName
        sleep 5s # Hold for user to read
        apt-get install alacarte |& tee -a $logFileName # Install alacarte
        dksay "GREEN" "\n GNOME installation complete." |& tee -a $logFileName
        sleep 2s # Hold for user to read
        dksay "YELLOW" "\n Checking if gdm3 is installed. If not it will be installed." |& tee -a $logFileName
        sleep 5s # Hold for user to read
        apt-get install gdm3 |& tee -a $logFileName # Install gdm3 if id does not exist

        # Check for GNOME setDefault switch
        if [ "$2" == '--setDefault' ]; then
            dksay "YELLOW" "\n Setting GNOME as default desktop environment." |& tee -a $logFileName
            sleep 5s # Hold for user to read
            dpkg-reconfigure gdm3 |& tee -a $logFileName
            checkSetDefaultDesktopEnvironment # Check for set default desktop environment
        else # Let user decide
            while true; do
                # Prompt user to set GNOME Desktop as default
                dksay "YELLOW" "\n Would you like to set GNOME as yout default desktop environment?\n\t1. Y (Yes) - to set default.\n\t2. N (No) to cancel or skip." |& tee -a $logFileName
                read -p ' option: ' dfChoice
                dfChoice=${dfChoice,,} # Convert to lowercase
                dksay "GREEN" " You chose : $dfChoice" |& tee -a $logFileName # Display choice

                if  [[ "$dfChoice" == 'yes' || "$dfChoice" == 'y' || "$dfChoice" == '1' ]]; then # Option : Yes
                    dksay "YELLOW" "\n Setting GNOME as default desktop environment." |& tee -a $logFileName
                    sleep 5s # Hold for user to read
                    dpkg-reconfigure gdm3 |& tee -a $logFileName
                    checkSetDefaultDesktopEnvironment # Check for set default desktop environment
                    break # Break from loop
                elif  [[ "$dfChoice" == 'no' || "$dfChoice" == 'n' || "$dfChoice" == '2' ]]; then # Option : No
                    dksay "NC" "\n Skipped..." |& tee -a $logFileName
                    break # Break from loop
                else dksay "GREEN" "\n Invalid entry!! Please try again." |& tee -a $logFileName # Invalid entry
                fi
                sleep 1 # Hold loop
            done
        fi
        installedGNOME=$[installedGNOME + 1] # Set GNOME installed to true
        dksay "GREEN" "\n Your GNOME Desktop is all set." |& tee -a $logFileName
        sectionBreak
    else exitScript --connectionFailure # Exit script on connection failure
    fi
}

# Function to install KDE PLASMA Desktop environment
function installKDEPlasmaDesktop(){
    # Install X Window Server
    installXWindowServer

    # Checking for internet connection before continuing
    if isConnected; then # Internet connection Established
        dksay "YELLOW" "\n\n Installing KDE PLASMA Desktop. This may take a while depending on your internet connection. Please wait..." |& tee -a $logFileName
        sleep 6s # Hold for user to read
        if [ "$1" == '--y' ]; then # Check for yes switch to install without confirmation
            apt-get install kde-full task-kde-desktop -y |& tee -a $logFileName # Install KDE PLASMA Desktop without confirmation
        else apt-get install kde-full task-kde-desktop |& tee -a $logFileName # Install KDE PLASMA Desktop with confirmation
        fi
        installedKDEPLASMA=$[installedKDEPLASMA + 1] # Set KDE PLASMA Desktop installed to true
        dksay "GREEN" "\n Your KDE PLASMA Desktop is all set." |& tee -a $logFileName
        checkSetDefaultDesktopEnvironment # Check for set default desktop environment
        sectionBreak
    else exitScript --connectionFailure # Exit script on connection failure
    fi
}

# Function to install XFCE Desktop environment
function installXFCEDesktop(){
    # Install X Window Server
    installXWindowServer

    # Checking for internet connection before continuing
    if isConnected; then # Internet connection Established
        dksay "YELLOW" "\n\n Installing XFCE Desktop. This may take a while depending on your internet connection. Please wait..." |& tee -a $logFileName
        sleep 6s # Hold for user to read
        if [ "$1" == '--y' ]; then # Check for yes switch to install without confirmation
            apt-get install xfce4 task-xfce-desktop -y |& tee -a $logFileName # Install XFCE4 Desktop with confirmation
        else apt-get install xfce4 task-xfce-desktop |& tee -a $logFileName # Install XFCE4 Desktop without confirmation
        fi
        installedXFCE=$[installedXFCE + 1] # Set XFCE Desktop installed to true
        dksay "GREEN" "\n Your XFCE Desktop is all set." |& tee -a $logFileName
        checkSetDefaultDesktopEnvironment # Check for set default desktop environment
        sectionBreak
    else exitScript --connectionFailure # Exit script on connection failure
    fi
}

# Function to install LXDE Desktop environment
function installLXDEDesktop(){
    # Install X Window Server
    installXWindowServer

    # Checking for internet connection before continuing
    if isConnected; then # Internet connection Established
        dksay "YELLOW" "\n\n Installing LXDE Desktop. This may take a while depending on your internet connection. Please wait..." |& tee -a $logFileName
        sleep 6s # Hold for user to read
        if [ "$1" == '--y' ]; then # Check for yes switch to install without confirmation
            apt-get install lxde task-lxde-desktop -y |& tee -a $logFileName # Install LXDE Desktop environment with confirmation
        else apt-get install lxde task-lxde-desktop |& tee -a $logFileName # Install LXDE Desktop environment without confirmation
        fi
        installedLXDE=$[installedLXDE + 1] # Set LXDE Desktop installed to true
        dksay "GREEN" "\n Your LXDE Desktop is all set." |& tee -a $logFileName
        checkSetDefaultDesktopEnvironment # Check for set default desktop environment
        sectionBreak
    else exitScript --connectionFailure # Exit script on connection failure
    fi
}

# Function to install LXQT Desktop environment
function installLXQTDesktop(){
    # Install X Window Server
    installXWindowServer

    # Checking for internet connection before continuing
    if isConnected; then # Internet connection Established
        dksay "YELLOW" "\n\n Installing LXQT Desktop. This may take a while depending on your internet connection. Please wait..." |& tee -a $logFileName
        sleep 6s # Hold for user to read
        if [ "$1" == '--y' ]; then # Check for yes switch to install without confirmation
            apt-get install lxqt sddm task-lxqt-desktop -y |& tee -a $logFileName # Install LXQT Desktop environment with confirmation
        else apt-get install lxqt sddm task-lxqt-desktop |& tee -a $logFileName # Install LXQT Desktop environment without confirmation
        fi
        installedLXQT=$[installedLXQT + 1] # Set LXQT Desktop installed to true
        dksay "GREEN" "\n Your LXQT Desktop is all set." |& tee -a $logFileName
        checkSetDefaultDesktopEnvironment # Check for set default desktop environment
        sectionBreak
    else exitScript --connectionFailure # Exit script on connection failure
    fi
}

# Function to install CINNAMON Desktop environment
function installCinnamonDesktop(){
    # Install X Window Server
    installXWindowServer

    # Checking for internet connection before continuing
    if isConnected; then # Internet connection Established
        dksay "YELLOW" "\n\n Installing Cinnamon Desktop. This may take a while depending on your internet connection. Please wait..." |& tee -a $logFileName
        sleep 6s # Hold for user to read
        if [ "$1" == '--y' ]; then # Check for yes switch to install without confirmation
            apt-get install cinnamon-desktop-environment task-cinnamon-desktop -y |& tee -a $logFileName # Install ENLIGHTENMENT Desktop environment with confirmation
        else apt-get install cinnamon-desktop-environment task-cinnamon-desktop |& tee -a $logFileName # Install ENLIGHTENMENT Desktop environment without confirmation
        fi
        installedCINNAMON=$[installedCINNAMON + 1] # Set CINNAMON Desktop installed to true
        dksay "GREEN" "\n Your Cinnamon Desktop is all set." |& tee -a $logFileName
        checkSetDefaultDesktopEnvironment # Check for set default desktop environment
        sectionBreak
    else exitScript --connectionFailure # Exit script on connection failure
    fi
}

# Function to install MATE Desktop environment
function installMateDesktop(){
    # Install X Window Server
    installXWindowServer

    # Checking for internet connection before continuing
    if isConnected; then # Internet connection Established
        dksay "YELLOW" "\n\n Installing Mate Desktop. This may take a while depending on your internet connection. Please wait..." |& tee -a $logFileName
        sleep 6s # Hold for user to read
        if [ "$1" == '--y' ]; then # Check for yes switch to install without confirmation
            apt-get install mate-desktop-environment task-mate-desktop -y |& tee -a $logFileName # Install MATE Desktop environment with confirmation
            dksay "YELLOW" "\n\n Installing Mate Extras..." |& tee -a $logFileName
            sleep 3s # Hold for user to read
            apt-get install mate-desktop-environment-extras -y |& tee -a $logFileName # Install MATE Desktop environment Extras
        else
          apt-get install mate-desktop-environment task-mate-desktop |& tee -a $logFileName # Install MATE Desktop environment without confirmation
          dksay "YELLOW" "\n\n Installing Mate Extras..." |& tee -a $logFileName
          sleep 3s # Hold for user to read
          apt-get install mate-desktop-environment-extras |& tee -a $logFileName # Install MATE Desktop environment Extras
        fi
        installedMATE=$[installedMATE + 1] # Set MATE Desktop installed to true
        dksay "GREEN" "\n Your Mate Desktop is all set." |& tee -a $logFileName
        checkSetDefaultDesktopEnvironment # Check for set default desktop environment
        sectionBreak
    else exitScript --connectionFailure # Exit script on connection failure
    fi
}

# Function to install BUDGIE Desktop environment
function installBudgieDesktop(){
    # Install X Window Server
    installXWindowServer

    # Checking for internet connection before continuing
    if isConnected; then # Internet connection Established
        dksay "YELLOW" "\n\n Installing Budgie Desktop. This will install GNOME if it is not installed as it depends on it.\n This may take a while depending on your internet connection. Please wait..." |& tee -a $logFileName
        sleep 8s # Hold for user to read
        if [ "$1" == '--y' ]; then # Check for yes switch to install without confirmation
            apt-get install budgie-desktop budgie-indicator-applet -y |& tee -a $logFileName # Install BUDGIE Desktop environment with confirmation
            apt-get install budgie.desktop -y |& tee -a $logFileName # Install BUDGIE Desktop environment with confirmation
        else
          apt-get install budgie-desktop budgie-indicator-applet |& tee -a $logFileName # Install BUDGIE Desktop environment without confirmation
          apt-get install budgie.desktop |& tee -a $logFileName # Install BUDGIE Desktop environment without confirmation
        fi
        installedBUDGIE=$[installedBUDGIE + 1] # Set BUDGIE Desktop installed to true
        dksay "GREEN" "\n Your BUDGIE Desktop is all set." |& tee -a $logFileName
        checkSetDefaultDesktopEnvironment # Check for set default desktop environment
        sectionBreak
    else exitScript --connectionFailure # Exit script on connection failure
    fi
}

# Function to install ENLIGHTENMENT Desktop environment
function installEnlightenmentDesktop(){
    # Install X Window Server
    installXWindowServer

    # Checking for internet connection before continuing
    if isConnected; then # Internet connection Established
        dksay "YELLOW" "\n\n Installing ENLIGHTENMENT Desktop dependencies." |& tee -a $logFileName
        sleep 4s # Hold for user to read
        apt-get install gcc g++ check libssl-dev libsystemd-dev libjpeg-dev libglib2.0-dev libgstreamer1.0-dev libluajit-5.1-dev libfreetype6-dev |& tee -a $logFileName
        apt-get install libfontconfig1-dev libfribidi-dev libx11-dev libxext-dev libxrender-dev libgl1-mesa-dev libgif-dev libtiff5-dev libpoppler-dev |& tee -a $logFileName
        apt-get install libpoppler-cpp-dev libspectre-dev libraw-dev librsvg2-dev libudev-dev libmount-dev libdbus-1-dev libpulse-dev libsndfile1-dev |& tee -a $logFileName
        apt-get install libxcursor-dev libxcomposite-dev libxinerama-dev libxrandr-dev libxtst-dev libxss-dev libbullet-dev libgstreamer-plugins-base1.0-dev doxygen git |& tee -a $logFileName

        dksay "YELLOW" "\n Installing ENLIGHTENMENT Desktop. This may take a while depending on your internet connection. Please wait..." |& tee -a $logFileName
        sleep 6s # Hold for user to read
        if [ "$1" == '--y' ]; then # Check for yes switch to install without confirmation
            apt-get install enlightenment -y |& tee -a $logFileName # Install ENLIGHTENMENT Desktop environment with confirmation
        else apt-get install enlightenment |& tee -a $logFileName # Install ENLIGHTENMENT Desktop environment without confirmation
        fi
        installedEnlightenment=$[installedEnlightenment + 1] # Set ENLIGHTENMENT Desktop installed to true
        dksay "GREEN" "\n Your ENLIGHTENMENT Desktop is all set." |& tee -a $logFileName
        checkSetDefaultDesktopEnvironment # Check for set default desktop environment
        sectionBreak
    else exitScript --connectionFailure # Exit script on connection failure
    fi
}

# Function to install KODI Desktop environment
function installKodiDesktop(){
    # Install X Window Server
    installXWindowServer

    # Checking for internet connection before continuing
    if isConnected; then # Internet connection Established
        dksay "YELLOW" "\n Installing KODI Desktop. This may take a while depending on your internet connection. Please wait..." |& tee -a $logFileName
        sleep 6s # Hold for user to read
        if [ "$1" == '--y' ]; then # Check for yes switch to install without confirmation
            apt-get install kodi -y |& tee -a $logFileName # Install KODI Desktop environment with confirmation
        else apt-get install kodi |& tee -a $logFileName # Install KODI Desktop environment without confirmation
        fi
        installedKODI=$[installedKODI + 1] # Set KODI Desktop installed to true
        dksay "GREEN" "\n Your KODI Desktop is all set." |& tee -a $logFileName
        checkSetDefaultDesktopEnvironment # Check for set default desktop environment
        sectionBreak
    else exitScript --connectionFailure # Exit script on connection failure
    fi
}

# Function to install all desktop environments
function installAllDesktopEnvironments(){
    # Install all desktop environments
    dksay "PURPLE" "\n\n Installing all $numberOfDesktopEnvironments desktop environments. This may take time depending on your internet connection. Please wait!\n"
    sleep 5s # Hold for user to read
    installKDEPlasmaDesktop --y # Install KDE PLASMA Desktop
    installXFCEDesktop --y # Install XFCE Desktop
    installLXDEDesktop --y # Install LXDE Desktop
    installLXQTDesktop --y # Install LXQT Desktop
    installCinnamonDesktop --y # Install CINNAMON Desktop
    installMateDesktop --y # Install MATE Desktop
    installBudgieDesktop --y # Install BUDGIE Desktop
    installEnlightenmentDesktop --y # Install ENLIGHTENMENT Desktop
    installKodiDesktop --y # Install KODI
    installGNOMEDesktop --y --setDefault # Install GNOME Desktop and set it as the default desktop

    # Check if all desktop environments were installed
    if [[ "$installedKDEPLASMA" -eq 1 && "$installedXFCE" -eq 1 && "$installedLXDE" -eq 1 && "$installedLXQT" -eq 1 && "$installedCINNAMON" -eq 1
          && "$installedMATE" -eq 1 && "$installedGNOME" -eq 1 && "$installedBUDGIE" -eq 1 && "$installedENLIGHTENMENT" -eq 1 ]];
    then # Installed all desktop environment
        installedAllEnvironments=1 # Set installed all to true using integer
    fi
}

# Function to install desktop environments
function installDesktopEnvironment(){
    declare -l reEnteredChoice="false"
    while true; do # Start infinite loop
        if [ "$reEnteredChoice" == 'false' ]; then
            dksay "YELLOW" "\n Please select the desktop environment to install from the options below." |& tee -a $logFileName
            sleep 4s # Hold for user to read
            dksay "NC" "
            \t\e[1;32m1. GNOME Desktop\e[0m: (gdm3)
                        \n\t\tGNOME is noteworthy for its efforts in usability and accessibility. Design professionals have been involved
                        in writing standards and recommendations. This has helped developers to create satisfying graphical user interfaces.
                        For administrators, GNOME seems to be better prepared for massive deployments. Many programming languages can be used
                        in developing applications interfacing to GNOME." |& tee -a $logFileName
            sleep 1s # Hold for user to read
            dksay "NC" "
            \t\e[1;32m2. KDE PLASMA Desktop\e[0m: (sddm)
                        \n\t\tKDE has had a rapid evolution based on a very hands-on approach.
                        KDE PLASMA Desktop is a perfectly mature desktop environment with a wide range of applications." |& tee -a $logFileName
            sleep 1s # Hold for user to read
            dksay "NC" "
            \t\e[1;32m3. XFCE Desktop \e[0m: (lightdm)
                        \n\t\tXfce is a simple and lightweight graphical desktop, a perfect match for computers with limited resources.
                        Xfce is based on the GTK+ toolkit, and several components are common across both desktops but does not aim at
                        being a vast project. Beyond the basic components of a modern desktop, it only provides a few specific
                        applications: a terminal, a calendar (Orage), an image viewer, a CD/DVD burning tool, a media player (Parole),
                        sound volume control and a text editor (mousepad)." |& tee -a $logFileName
            sleep 1s # Hold for user to read
            dksay "NC" "
            \t\e[1;32m4. LXDE Desktop \e[0m:
                        \n\t\tLXDE is written in the C programming language, using the GTK+ 2 toolkit, and runs on Unix and
                        other POSIX-compliant platforms, such as Linux and BSDs. The LXDE project aims to provide a fast
                        and energy-efficient desktop environment with low memory usage." |& tee -a $logFileName
            sleep 1s # Hold for user to read
            dksay "NC" "
            \t\e[1;32m5. LXQT Desktop \e[0m:
                        \n\t\tLXQt is an advanced, easy-to-use, and fast desktop environment based on Qt technologies. It has been
                        tailored for users who value simplicity, speed, and an intuitive interface. Unlike most desktop environments,
                        LXQt also works fine with less powerful machines." |& tee -a $logFileName
            sleep 1s # Hold for user to read
            dksay "NC" "
            \t\e[1;32m6. CINNAMON Desktop \e[0m:
                        \n\t\tCinnamon is a free and open-source desktop environment for the X Window System that derives from GNOME 3 but follows
                        traditional desktop metaphor conventions. Cinnamon is the principal desktop environment of the Linux Mint distribution and
                        is available as an optional desktop for other Linux distributions and other Unix-like operating systems as well." |& tee -a $logFileName
            sleep 1s # Hold for user to read
            dksay "NC" "
            \t\e[1;32m7. Mate Desktop \e[0m:
                        \n\t\tThe MATE Desktop Environment is the continuation of GNOME 2. It provides an intuitive and attractive desktop environment
                        using traditional metaphors for Linux and other Unix-like operating systems. MATE is under active development to add support
                        for new technologies while preserving a traditional desktop experience. Mate feels old school." |& tee -a $logFileName
            sleep 1s # Hold for user to read
            dksay "NC" "
            \t\e[1;32m8. Budgie Desktop \e[0m:
                        \n\t\tBudgie is the popular desktop environment of the Solus OS distribution. It\’s quickly gained in popularity and spread around
                        the Linux world. Budgie desktop tightly integrates with the GNOME stack, employing underlying technologies to offer an alternative
                        desktop experience. Budgie applications generally use GTK and header bars similar to GNOME applications. Budgie builds what is effectively
                        a Favorites list automatically as the user works, moving categories and applications toward the top of menus when they are used.
                        It will install the minimal GNOME based package-set together with the key budgie-desktop packages to produce a working desktop environment." |& tee -a $logFileName
            sleep 1s # Hold for user to read
            dksay "NC" "
            \t\e[1;32m9. Enlightenment Desktop \e[0m:
                        \n\t\tEnlightenment is an advanced window manager for X11. Unique features include: a fully animated background, nice drop shadows around
                        windows, backed by an extremely clean and optimized foundation of APIs." |& tee -a $logFileName
            dksay "NC" "
            \t\e[1;32m10. Kodi Desktop \e[0m:
                        \n\t\tKodi spawned from the love of media. It is an entertainment hub that brings all your digital media together into a beautiful and user
                        friendly package. It is 100% free and open source, very customisable and runs on a wide variety of devices. It is supported by a dedicated team
                        of volunteers and a huge community." |& tee -a $logFileName
            dksay "NC" "
            \t\e[1;32m11. Install all of them \e[0m: This will set GNOME Desktop as your default desktop environment." |& tee -a $logFileName
            sleep 1s # Hold for user to read
            dksay "NC" "
            \t\e[1;32m12 or 0. To Skip / Cancel \e[0m: This will skip desktop environment installation." |& tee -a $logFileName
            sleep 1s # Hold loop

            read -p ' option: ' choice
            choice=${choice,,} # Convert to lowercase
            dksay "GREEN" " You chose : $choice" |& tee -a $logFileName # Display choice
        fi
        # Check chosen option
        if  [[ "$choice" == '1' || "$choice" == 'gnome' ]]; then # Option : GNOME Desktop
            # Check if desktop environment value was is empty
            # This is for those who had installed some desktop environment.
            # This ensures that they are not forced to make GNOME Desktop as their default if they were running any other desktop environment
            # This stage will be skipped if another desktop environment was found during check.
            if [ -z "$currentDesktopEnvironment" ]; then # (Variable empty) - Desktop environment not found
                installGNOMEDesktop --y --setDefault # Install GNOME Desktop and set it as the default desktop
            else
                installGNOMEDesktop # Install GNOME Desktop
            fi
            # Query if user wants to install another desktop environment after installing the previous
            if queryInstallAnotherDesktopEnvironment; then # Installation of another desktop environment - true
                sleep 1 # Hold loop
                continue # Resume iterations
            else # Installation of another desktop environment - false
                break # Break from loop
            fi
        elif  [[ "$choice" == '2' || "$choice" == 'kde' || "$choice" == 'kde plasma' || "$choice" == 'kdeplasma' ]]; then # Option : KDE PLASMA Desktop
            installKDEPlasmaDesktop # Install KDE PLASMA Desktop Desktop

            # Query if user wants to install another desktop environment after installing the previous
            if queryInstallAnotherDesktopEnvironment; then # Installation of another desktop environment - true
                sleep 1 # Hold loop
                continue # Resume iterations
            else # Installation of another desktop environment - false
                break # Break from loop
            fi
        elif  [[ "$choice" == '3' || "$choice" == 'xfce' ]]; then # Option : XFCE Desktop
            installXFCEDesktop # Install XFCE Desktop

            # Query if user wants to install another desktop environment after installing the previous
            if queryInstallAnotherDesktopEnvironment; then # Installation of another desktop environment - true
                sleep 1 # Hold loop
                continue # Resume iterations
            else # Installation of another desktop environment - false
                break # Break from loop
            fi
        elif  [[ "$choice" == '4' || "$choice" == 'lxde' ]]; then # Option : LXDE Desktop
            installLXDEDesktop # Install LXDE Desktop

            # Query if user wants to install another desktop environment after installing the previous
            if queryInstallAnotherDesktopEnvironment; then # Installation of another desktop environment - true
                sleep 1 # Hold loop
                continue # Resume iterations
            else # Installation of another desktop environment - false
                break # Break from loop
            fi
          elif  [[ "$choice" == '5' || "$choice" == 'lxqt' ]]; then # Option : LXQT Desktop
              installLXQTDesktop # Install LXQT Desktop

              # Query if user wants to install another desktop environment after installing the previous
              if queryInstallAnotherDesktopEnvironment; then # Installation of another desktop environment - true
                  sleep 1 # Hold loop
                  continue # Resume iterations
              else # Installation of another desktop environment - false
                  break # Break from loop
              fi
          elif  [[ "$choice" == '6' || "$choice" == 'cinnamon' || "$choice" == 'cinamon' ]]; then # Option : Cinnamon
              installCinnamonDesktop # Install Cinnamon Desktop

              # Query if user wants to install another desktop environment after installing the previous
              if queryInstallAnotherDesktopEnvironment; then # Installation of another desktop environment - true
                  sleep 1 # Hold loop
                  continue # Resume iterations
              else # Installation of another desktop environment - false
                  break # Break from loop
              fi
        elif  [[ "$choice" == '7' || "$choice" == 'mate' ]]; then # Option : MATE Desktop
            installMateDesktop # Install Mate Desktop

            # Query if user wants to install another desktop environment after installing the previous
            if queryInstallAnotherDesktopEnvironment; then # Installation of another desktop environment - true
                sleep 1 # Hold loop
                continue # Resume iterations
            else # Installation of another desktop environment - false
                break # Break from loop
            fi
        elif  [[ "$choice" == '8' || "$choice" == 'budgie' ]]; then # Option : BUDGIE Desktop
            installBudgieDesktop # Install Mate Desktop

            # Query if user wants to install another desktop environment after installing the previous
            if queryInstallAnotherDesktopEnvironment; then # Installation of another desktop environment - true
                sleep 1 # Hold loop
                continue # Resume iterations
            else # Installation of another desktop environment - false
                break # Break from loop
            fi
        elif  [[ "$choice" == '9' || "$choice" == 'enlightenment' ]]; then # Option : ENLIGHTENMENT Desktop
            installEnlightenmentDesktop # Install ENLIGHTENMENT Desktop

            # Query if user wants to install another desktop environment after installing the previous
            if queryInstallAnotherDesktopEnvironment; then # Installation of another desktop environment - true
                sleep 1 # Hold loop
                continue # Resume iterations
            else # Installation of another desktop environment - false
                break # Break from loop
            fi
        elif  [[ "$choice" == '10' || "$choice" == 'kodi' ]]; then # Option : KODI Desktop
            installKodiDesktop # Install KODI Desktop

            # Query if user wants to install another desktop environment after installing the previous
            if queryInstallAnotherDesktopEnvironment; then # Installation of another desktop environment - true
                sleep 1 # Hold loop
                continue # Resume iterations
            else # Installation of another desktop environment - false
                break # Break from loop
            fi
        elif  [[ "$choice" == '11' || "$choice" == 'install all of them' || "$choice" == 'install all' || "$choice" == 'all' ]]; then
            installAllDesktopEnvironments # Install all desktop environments
            break # Break from loop
        elif  [[ "$choice" == '12' || "$choice" == '0' || "$choice" == 'skip' || "$choice" == 'cancel' || "$choice" == 'exit' ]]; then
            dksay "RED" "\n Setup cancelled!!" |& tee -a $logFileName
            setupCancelled=$[setupCancelled + 1 ] # Increment setupCancelled value
            sleep 1s # Hold for user to read
            break # Break from loop
        else
          # Invalid entry
          dksay "GREEN" "\n Invalid desktop selection!! Please try again." |& tee -a $logFileName

          # Re-enter choice
          read -p ' option: ' choice
          choice=${choice,,} # Convert to lowercases
          dksay "GREEN" "You chose : $choice" # Display choice
          reEnteredChoice="true"
        fi
        sleep 1 # Hold loop
    done
}

# Function to initiate and setup newly installed desktop environments for users who
# did not have a desktop environment at the beginning
function initSetupDesktopEnvironments(){
    # Setting systemd to boot into graphical.target instead of multi-user.target
    dksay "YELLOW" "\n Setting systemd to boot to graphicat.target instead of multi-user.target." |& tee -a $logFileName
    sleep 2s # Hold for user to read
    systemctl set-default graphical.target |& tee -a $logFileName # Start / restart gdm3
    sectionBreak

    # Restart desktop environments if no desktop environment had been installed initially
    if [ -z "$currentDesktopEnvironment" ]; # Check if current desktop environment vaue was initially empty
    then # Installed all and GNOME Desktop is the default
        if [ "$installedAllEnvironments" -eq 1 ]; then # Gnome is default
            dksay "YELLOW" "\n Running --replace GNOME Desktop and disown to break HUP signal for all jobs if exists." |& tee -a $logFileName
            sleep 2s # Hold for user to read
            gnome-shell --replace & disown |& tee -a $logFileName # --replace and disown to break HUP signal for all jobs if exists
            dksay "YELLOW" "\n Restarting gdm3 for GNOME Desktop." |& tee -a $logFileName
            sleep 2s # Hold for user to read
            systemctl restart gdm3 |& tee -a $logFileName # Start / restart gdm3 for GNOME Desktop
        # Only if GNOME Installed
        elif [[ "$installedKDEPLASMA" -eq 0 && "$installedXFCE" -eq 0 && "$installedLXDE" -eq 0 && "$installedLXQT" -eq 0 && "$installedCINNAMON" -eq 0 &&
                "$installedMATE" -eq 0 && "$installedBUDGIE" -eq 0 && "$installedEnlightenment" -eq 0 && "$installedKODI" -eq 0 && "$installedGNOME" -eq 1 &&
                "$installedAllEnvironments" -eq 0 ]]; then
            dksay "YELLOW" "\n Running --replace GNOME Desktop and disown." |& tee -a $logFileName
            sleep 2s # Hold for user to read
            gnome-shell --replace & disown |& tee -a $logFileName # --replace and disown to break HUP signal for all jobs if exists
            dksay "YELLOW" "\n Restarting gdm3 for GNOME Desktop." |& tee -a $logFileName
            sleep 2s # Hold for user to read
            systemctl restart gdm3 |& tee -a $logFileName # Start / restart gdm3 for GNOME Desktop
        # Only if KDE PLASMA Desktop Installed
        elif [[ "$installedKDEPLASMA" -eq 1 && "$installedXFCE" -eq 0 && "$installedLXDE" -eq 0 && "$installedLXQT" -eq 0 && "$installedCINNAMON" -eq 0 &&
                "$installedMATE" -eq 0 && "$installedBUDGIE" -eq 0 && "$installedEnlightenment" -eq 0 && "$installedKODI" -eq 0 && "$installedGNOME" -eq 0 &&
                "$installedAllEnvironments" -eq 0 ]]; then
            dksay "YELLOW" "\n Enabling sddm for KDE PLASMA Desktop." |& tee -a $logFileName
            systemctl enable sddm.service |& tee -a $logFileName # Enable sddm.service for KDE PLASMA Desktop
            dksay "YELLOW" "\n Reconfiguring sddm for KDE PLASMA Desktop." |& tee -a $logFileName
            dpkg-reconfigure sddm |& tee -a $logFileName
            dksay "YELLOW" "\n Restarting sddm for KDE PLASMA Desktop." |& tee -a $logFileName
            systemctl restart sddm |& tee -a $logFileName
            sleep 2s # Hold for user to read
        # Only if XFCE Desktop Installed
        elif [[ "$installedKDEPLASMA" -eq 0 && "$installedXFCE" -eq 1 && "$installedLXDE" -eq 0 && "$installedLXQT" -eq 0 && "$installedCINNAMON" -eq 0 &&
                "$installedMATE" -eq 0 && "$installedBUDGIE" -eq 0 && "$installedEnlightenment" -eq 0 && "$installedKODI" -eq 0 && "$installedGNOME" -eq 0 &&
                "$installedAllEnvironments" -eq 0 ]]; then
            dksay "YELLOW" "\n Restarting lightdm for XFCE Desktop." |& tee -a $logFileName
            sleep 2s # Hold for user to read
            dksay "YELLOW" "\n Re-configuring lightdm for XFCE Desktop." |& tee -a $logFileName
            sleep 2s # Hold for user to read
            dpkg-reconfigure lightdm |& tee -a $logFileName # Re-configure lightdm to load after boot
            dksay "YELLOW" "\n Creating a symlink to the unit file in /lib/systemd/system in /etc/systemd/system for lightdm to start at boot." |& tee -a $logFileName
            sleep 2s # Hold for user to read
            `ll /etc/systemd/system/display-manager.service` |& tee -a $logFileName
            `ln -s /lib/systemd/system/lightdm.service /etc/systemd/system/display-manager.service` |& tee -a $logFileName
            dksay "YELLOW" "\n Restarting lightdm and resetting it for XFCE Desktop." |& tee -a $logFileName
            sleep 2s # Hold for user to read
            systemctl restart lightdm || xfwm4 --replace |& tee -a $logFileName # Restart lightdm for XFCE Desktop and reset
        # Only if ( LXDE or LXQT Desktops ) Installed
        elif [[ "$installedLXDE" -eq 1 || "$installedLXQT" -eq 1 && "$installedKDEPLASMA" -eq 0 && "$installedXFCE" -eq 0 && "$installedCINNAMON" -eq 0 &&
                "$installedMATE" -eq 0 && "$installedBUDGIE" -eq 0 && "$installedEnlightenment" -eq 0 && "$installedKODI" -eq 0 && "$installedGNOME" -eq 0 &&
                "$installedAllEnvironments" -eq 0 ]]; then
            if [ "$installedLXDE" -eq 1 ]; then
                dksay "YELLOW" "\n Restarting LXDE." |& tee -a $logFileName
                sleep 2s # Hold for user to read
                exec startlxde |& tee -a $logFileName # Start LXDE Desktop from terminal
            elif [ "$installedLXQT" -eq 1 ]; then
                dksay "YELLOW" "\n Restarting LXQT." |& tee -a $logFileName
                sleep 2s # Hold for user to read
                exec startlxqt |& tee -a $logFileName # Start LXQT Desktop from terminal
            fi
        # Only if CINNAMON Desktop Installed
        elif [[ "$installedKDEPLASMA" -eq 0 && "$installedXFCE" -eq 0 && "$installedLXDE" -eq 0 && "$installedLXQT" -eq 0 && "$installedCINNAMON" -eq 1 &&
                "$installedMATE" -eq 0 && "$installedBUDGIE" -eq 0 && "$installedEnlightenment" -eq 0 && "$installedKODI" -eq 0 && "$installedGNOME" -eq 0 &&
                "$installedAllEnvironments" -eq 0 ]]; then
            killall cinnamon |& tee -a $logFileName # Kill all instances of CINNAMON Desktop if exists
            dksay "YELLOW" "\n Re-configuring Cinnamon Desktop." |& tee -a $logFileName
            sleep 2s # Hold for user to read
            dpkg-reconfigure cinnamon |& tee -a $logFileName # Re-configure CINNAMON Desktop
            dksay "YELLOW" "\n Running --replace for CINNAMON Desktop and disown to break HUP signal for all jobs if exists." |& tee -a $logFileName
            sleep 2s # Hold for user to read
            cinnamon --replace && disown |& tee -a $logFileName # Replace CINNAMON Desktop and disown to break HUP signal for all jobs if exists
            dksay "YELLOW" "\n Restarting mdm for CINNAMON Desktop." |& tee -a $logFileName
            sleep 2s # Hold for user to read
            service restart mdm |& tee -a $logFileName # Restart mdm for CINNAMON Desktop
        # Only if MATE Desktop Installed
        elif [[ "$installedKDEPLASMA" -eq 0 && "$installedXFCE" -eq 0 && "$installedLXDE" -eq 0 && "$installedLXQT" -eq 0 && "$installedCINNAMON" -eq 0 &&
                "$installedMATE" -eq 1 && "$installedBUDGIE" -eq 0 && "$installedEnlightenment" -eq 0 && "$installedKODI" -eq 0 && "$installedGNOME" -eq 0 &&
                "$installedAllEnvironments" -eq 0 ]]; then
            killall mate-panel |& tee -a $logFileName # Kill all instances of MATE-PANEL if exists
            dksay "YELLOW" "\n Re-configuring MATE-PANEL." |& tee -a $logFileName
            sleep 2s # Hold for user to read
            dpkg-reconfigure mate-panel |& tee -a $logFileName # Re-configure CINNAMON Desktop
            dksay "YELLOW" "\n Running --replace for MATE-PANEL and disown to break HUP signal for all jobs if exists." |& tee -a $logFileName
            sleep 2s # Hold for user to read
            mate-panel --replace && disown |& tee -a $logFileName # Replace MATE-PANEL and disown to break HUP signal for all jobs if exists
        # Only if Budgie Installed
        elif [[ "$installedKDEPLASMA" -eq 0 && "$installedXFCE" -eq 0 && "$installedLXDE" -eq 0 && "$installedLXQT" -eq 0 && "$installedCINNAMON" -eq 0 &&
                "$installedMATE" -eq 0 && "$installedBUDGIE" -eq 1 && "$installedEnlightenment" -eq 0 && "$installedKODI" -eq 0 && "$installedGNOME" -eq 0 &&
                "$installedAllEnvironments" -eq 0 ]]; then
            killall budgie-panel |& tee -a $logFileName # Kill all instances of BUDGIE-PANEL if exists
            dksay "YELLOW" "\n Re-configuring BUDGIE-DESKTOP." |& tee -a $logFileName
            sleep 2s # Hold for user to read
            dpkg-reconfigure budgie-desktop |& tee -a $logFileName # Re-configure BUDGIE Desktop
            dksay "YELLOW" "\n Running --replace for BUDGIE-PANEL and disown to break HUP signal for all jobs if exists." |& tee -a $logFileName
            sleep 2s # Hold for user to read
            budgie-panel --replace && disown |& tee -a $logFileName # Replace BUDGIE-PANEL and disown to break HUP signal for all jobs if exists
        # Only if ENLIGHTENMENT Desktop Installed
        elif [[ "$installedKDEPLASMA" -eq 0 && "$installedXFCE" -eq 0 && "$installedLXDE" -eq 0 && "$installedLXQT" -eq 0 && "$installedCINNAMON" -eq 0 &&
                "$installedMATE" -eq 0 && "$installedBUDGIE" -eq 0 && "$installedEnlightenment" -eq 1 && "$installedKODI" -eq 0 && "$installedGNOME" -eq 0 &&
                "$installedAllEnvironments" -eq 0 ]]; then
            killall enlightenment & tee -a $logFileName # Kill all instances of ENLIGHTENMENT Desktop if exists
            dksay "YELLOW" "\n Re-configuring ENLIGHTENMENT Desktop." |& tee -a $logFileName
            sleep 2s # Hold for user to read
            dpkg-reconfigure enlightenment |& tee -a $logFileName # Re-configure ENLIGHTENMENT Desktop Desktop
            dksay "YELLOW" "\n Starting ENLIGHTENMENT Desktop." |& tee -a $logFileName
            sleep 2s # Hold for user to read
            enlightenment_start # Start ENLIGHTENMENT Desktop
        # Only if KODI Desktop Installed
        elif [[ "$installedKDEPLASMA" -eq 0 && "$installedXFCE" -eq 0 && "$installedLXDE" -eq 0 && "$installedLXQT" -eq 0 && "$installedCINNAMON" -eq 0 &&
                "$installedMATE" -eq 0 && "$installedBUDGIE" -eq 0 && "$installedEnlightenment" -eq 0 && "$installedKODI" -eq 1 && "$installedGNOME" -eq 0 &&
                "$installedAllEnvironments" -eq 0 ]]; then
            killall kodi & tee -a $logFileName # Kill all instances of KODI Desktop if exists
            dksay "YELLOW" "\n Re-configuring KODI Desktop." |& tee -a $logFileName
            sleep 2s # Hold for user to read
            dpkg-reconfigure kodi |& tee -a $logFileName # Re-configure KODI Desktop Desktop
            dksay "YELLOW" "\n Starting KODI Desktop." |& tee -a $logFileName
            sleep 2s # Hold for user to read
            kodi # Start kodi Desktop
        fi
    fi
}


########
# Beginning of script
########
initLogFile # Initiate log file

dksay "RED" 		"\n\n Hello there user $USER!!. \n" |& tee -a $logFileName
dksay "YELLOW"	" This script will help you install some or all listed desktop environments into your debian or ubuntu linux.\n" |& tee -a $logFileName
sleep 10s # Hold for user to read

# Check if user is running as root
declare -l user=$USER # Declare user variable as lowercase
if [ "$user" != 'root' ]; then
    dksay "YELLOW" "\n This script works best when run as root.\n Please run it as root if you encounter any issues.\n" |& tee -a $logFileName
    sleep 4s # Hold for user to read
fi
sectionBreak

dksay "GREEN" " Script     : $scriptName" |& tee -a $logFileName
dksay "GREEN" " Version    : $scriptVersion" |& tee -a $logFileName
dksay "GREEN" " License    : MIT" |& tee -a $logFileName
dksay "GREEN" " Author     : David Kariuki (dk)\n" |& tee -a $logFileName

dksay "GREEN" "\n Initializing script...!!\n" |& tee -a $logFileName
sleep 4s # Hold for user to read

# Checking for internet connection before continuing
if ! isConnected; then # Internet connection failed
  exitScript --connectionFailure # Exit script on connection failure
fi

# Debug and configure packages, update system packages, upgrade software packages and update apt-file
checkDebugAndRollback --debug --update-upgrade

# Check for desktop environment
checkForDesktopEnvironment

# Show install desktop environment options
installDesktopEnvironment

# Initiate and setup newly installed desktop environments for users
# who did not have a desktop environment at the beginning
initSetupDesktopEnvironments

# Exit script
exitScript --end
