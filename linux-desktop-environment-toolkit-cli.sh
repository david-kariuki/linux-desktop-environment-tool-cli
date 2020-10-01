# Copyright (c) 2020 by David Kariuki (dk). All Rights Reserved.

#!/bin/bash

: ' cPrint - Custom function to create a custom coloured print
    |& tee -a $logFileName - append output stream to logs and output to terminal'
1="" # Empty any parameter passed by user during script exercution
declare -r targetLinux="Debian Linux"
declare -l -r scriptName="linux-desktop-environment-toolkit-cli" # Script file name (Set to lowers and read-only)
declare -l -r logFileName="$scriptName-logs.txt" # Script log-file name (Set to lowers and read-only)
declare scriptVersion="3.6" # Script version
declare -i -r numberOfDesktopEnvironments=10 # Stores total number of desktop environments
declare -l -r networkTestUrl="www.google.com" # Stores the networkTestUrl (Set to lowers and read-only)
declare -r numberExpression='^[0-9]+$' # Number expression
declare -l currentDesktopEnvironment="" # Value of the current installed desktop environment
declare listOfInstalledDesktopEnvironments="" # A numbered list of all installed desktop environments with more options
declare uninstallationList="" # List of desktop environments to be uninstalled
declare -l startTime="" # Start time of execution
declare -l totalExecutionTime="" # Total execution time in days:hours:minutes:seconds
declare -i setupCancelled=0 # Value to indicate setup cancellation
clear=clear # Command to clear terminal

: ' Variables to store true or false in integer if associated desktop environment has just been installed '
declare -l justInstalledGNOME=0
declare -l justInstalledKDEPLASMA=0
declare -l justInstalledXFCE=0
declare -l justInstalledLXDE=0
declare -l justInstalledLXQT=0
declare -l justInstalledCINNAMON=0
declare -l justInstalledMATE=0
declare -l justInstalledBUDGIE=0
declare -l justInstalledENLIGHTENMENT=0
declare -l justInstalledKODI=0
declare -i justInstalledAllEnvironments=0

: ' Variables to store true or false in integer if associated desktop environment was found to have been
    installed after checking for all installed desktop environments.'
declare -i foundGNOMEInstalled=0
declare -i foundKDEPLASMAInstalled=0
declare -i foundXFCEInstalled=0
declare -i foundLXDEInstalled=0
declare -i foundLXQTInstalled=0
declare -i foundCINNAMONInstalled=0
declare -i foundMATEInstalled=0
declare -i foundBUDGIEInstalled=0
declare -i foundENLIGHTENMENTInstalled=0
declare -i foundKODIInstalled=0
declare -i XServerInstalled=0 checkedForXServer=0
declare -i checkedForLinuxHeaders=0 linuxHeadersInstalled=0

# Total number of installed desktop environment
declare -i noOfInstalledDesktopEnvironments=0
declare -l xSessionsPath=/usr/share/xsessions/ # XSessions path

: 'Stores uninstallation order to ensure that the default desktop environment
    is uninstalled as the last option since uninstalling the current desktop
    may halt the running of this script in gui terminal'
declare -a uninstallOrder=()
declare -a scriptActions=() # Stores the actions performed by the script


# Function to create a custom coloured print
function cPrint(){
    RED="\033[0;31m"    # 31 - red    : "\e[1;31m$1\e[0m"
    GREEN="\033[0;32m"  # 32 - green  : "\e[1;32m$1\e[0m"
    YELLOW="\033[1;33m" # 33 - yellow : "\e[1;33m$1\e[0m"
    BLUE="\033[1;34m"   # 34 - blue   : "\e[1;34m$1\e[0m"
    PURPLE="\033[1;35m" # 35 - purple : "\e[1;35m$1\e[0m"
    NC="\033[0m"        # No Color    : "\e[0m$1\e[0m"
    # Display coloured text setting its background color to black
    printf "\e[48;5;0m${!1}\n ${2} ${NC}\n" || exit
}

# Function to space out different sections
function sectionBreak(){
    cPrint "NC" "\n" |& tee -a $logFileName # Print without color
}

# Function to display connection established message
function connEst(){
    cPrint "GREEN" "Internet connection established.\n" |& tee -a $logFileName
    sleep 2s # Hold for user to read
}

# Function to display connection failed message
function connFailed(){
    cPrint "RED" "Internet connection failed!!!" |& tee -a $logFileName
    sleep 2s # Hold for user to read
}

# Function to display script information
function displayScriptInfo(){
    cPrint "NC" "About\n   Script       : $scriptName.\n   Target Linux : $targetLinux.\n   Version      : $scriptVersion\n   License      : MIT Licence.\n   Developer    : David Kariuki (dk)\n" |& tee -a $logFileName
}

# Function to hold terminal with simple terminal animation
function holdTerminal(){
  local -r initialTime=`date +%s` # Get start time
  local -r characters=" //--\\|| "
  while :
  do
      local currentTime=`date +%s`
      for (( i=0; i<${#characters}; i++ ))
      do
          sleep .1
          echo -en "  ${characters:$i:1}" "\r"
      done
      difference=$((currentTime-initialTime))
      if [[ "$difference" -eq $1 ]]
      then
          break
      fi
  done
}

# Function to format time from seconds to days:hours:minutes:seconds
function formatTime() {
    local inputSeconds=$1 local minutes=0 hour=0 day=0
    if((inputSeconds>59))
    then
        ((seconds=inputSeconds%60))
        ((inputSeconds=inputSeconds/60))
        if((inputSeconds>59))
        then
            ((minutes=inputSeconds%60))
            ((inputSeconds=inputSeconds/60))
            if((inputSeconds>23))
            then
                ((hour=inputSeconds%24))
                ((day=inputSeconds/24))
            else ((hour=inputSeconds))
            fi
        else ((minutes=inputSeconds))
        fi
    else ((seconds=inputSeconds))
    fi
    unset totalExecutionTime
    totalExecutionTime="${totalExecutionTime}$day"
    totalExecutionTime="${totalExecutionTime}d "
    totalExecutionTime="${totalExecutionTime}$hour"
    totalExecutionTime="${totalExecutionTime}h "
    totalExecutionTime="${totalExecutionTime}$minutes"
    totalExecutionTime="${totalExecutionTime}m "
    totalExecutionTime="${totalExecutionTime}$seconds"
    totalExecutionTime="${totalExecutionTime}s "
}

# Function to initiate logfile
function initLogFile(){
    cd ~ || exit # Change directory to users' home directory
    # Delete log file if/not it exists to prevent appending to previous logs
    rm -f $logFileName
    touch $logFileName # Creating log file
    currentDate="Date : `date`\n\n" # Get current date
    # Add script actions to script actions array
    scriptActions=( "${scriptActions[@]}" "Created log file" )
    # Log date without displaying on terminal
    printf $currentDate &>> $logFileName
}

# Function to check for and install linux headers
function checkInstallLinuxHeaders(){
    # Path to linux headers
    headersPath=/usr/src/linux-headers-$(uname -r)

    # Check for linux headers installation
    if check=$(ls -l $headersPath &> /dev/null)
    then # Linux headers installed

        # Prevent message showing many times during loop
        if [ "$checkedForLinuxHeaders" -eq 0 ]
        then
            cPrint "GREEN" "Checked for linux headers. Linux headers installed.\n"
            holdTerminal 1 # Hold
            checkedForLinuxHeaders=1
            linuxHeadersInstalled=1
        fi
    else # Linux headers not installed

        # Install linux headers
        cPrint "YELLOW" "Installing linux headers.\n"
        apt-get install linux-headers-$(uname -r) |& tee -a $logFileName

        checkDebugAndRollback hapa
    fi
}

# Function to install netcat and and start script
function initScript(){
    initLogFile # Create log file
    # Install netcat if not installed to be used for connection check
    cPrint "YELLOW" "Fetching required packages. Please wait..."
    apt-get install netcat &>> $logFileName

    ${clear} # Clear terminal

    echo ""; cPrint "RED" "Hello $USER!!." |& tee -a $logFileName
    cPrint "YELLOW" "This script will help you install and uninstall the supported $targetLinux desktop environments." |& tee -a $logFileName
    holdTerminal 6 # Hold for user to read

    # Check if user is running as root
    checkIfUserIsRoot
    sectionBreak

    displayScriptInfo # Display Script Information
}

# Function to check if user is running as root
function checkIfUserIsRoot(){
    declare -l -r user=$USER # Declare user variable as lowercase
    if [ "$user" != 'root' ]
    then
        cPrint "RED" "This script works fully when run as root.\n Please run it as root to avoid issues/errors.\n" |& tee -a $logFileName
        holdTerminal 3 # Hold for user to read
        exitScript --end
    fi
}

# Function to check for internet connection and validate security on connection
function isConnected(){
    # Creating integer variable
    local -i count=0 # Declare loop count variable
    local -i -r retrNum=4 # Declare and set number of retries to read-only
    local -i -r maxRetr=$[retrNum + 1] # Declare and set max retry to read-only
    local -i -r countDownTime=30 # Declare and set retry to read-only

    while :
    do # Starting infinite loop
        cPrint "YELLOW" "Checking for internet connection!!" |& tee -a $logFileName
        if trap `nc -zw1 $networkTestUrl 443` && echo |openssl s_client -connect $networkTestUrl:443 2>&1 |awk '
            handshake && $1 == "Verification" { if ($2=="OK") exit; exit 1 }
	          $1 $2 == "SSLhandshake" { handshake = 1 }'
        then # Internet connection established
            connEst # Display internet connection established message
            return $(true) # Exit loop returning true
        else # Internet connection failed
            connFailed # Display internet connection failed message

            if [ "$count" == 0 ]
            then
                cPrint "YELLOW" "Attemting re-connection...\n Max number of retries : \e[0m$maxRetr\e[0m\n" |& tee -a $logFileName
            fi
            # Check for max number of retries
            if [ "$count" -gt "$retrNum" ]
            then
                cPrint "YELLOW" "Number of retries: $count" |& tee -a $logFileName # Display number of retries
                return $(false) # Exit loop returning false
            else
                count=$[count + 1] # Increment loop counter variable

                # Run countdown
                date1=$((`date +%s` + $countDownTime))
                while [ "$date1" -ge "$(date +%s)" ]
                do
                  echo -ne " \e[1;32mRetrying connection after :\e[0m \e[1;33m$(date -u --date @$(($date1 - `date +%s`)) +%H:%M:%S)\r\e[0m" |& tee -a $logFileName
                  sleep 0.1
                done
            fi
        fi
        sleep 1 # Hold loop
    done
}

# Function to check for script action
function checkForScriptAction(){
    : '
    tr ' ' '\n' - Convert all spaces to newlines. Sort expects input to be on separate lines.
    sort -u - sort and retain only unique elements, tr '\n' ' ' - convert the newlines back to spaces.'
    # Remove array duplicates
    scriptActions=($(echo "${scriptActions[@]}" | tr ' ' '\n' | sort -u | tr '\n' ' '))
    # Get action list array as string
    actionsList=${scriptActions[@]}
    # Check for required script action
    if [[ $actionsList == *$1* ]]
    then
        return $(true) # Return true if found
    else
        return $(false)  # Return false if otherwise
    fi
}

# Function to update system packages, upgrade software packages
# and update apt-file
function updateAndUpgrade(){
    # Checking for connection after every major sep incase of network
    # failure during one stage
    if isConnected
    then # Checking for internet connection
        # Internet connection established
        cPrint "YELLOW" "Updating system packages." |& tee -a $logFileName
        holdTerminal 2 # Hold for user to read
        apt-get update |& tee -a $logFileName

        # Add script actions to script actions array
        scriptActions=( "${scriptActions[@]}" "update" )
        sectionBreak
    else
        apt-get check |& tee -a $logFileName
        apt-get --fix-broken install |& tee -a $logFileName
        dpkg --configure -a |& tee -a $logFileName
        apt-get autoremove -y |& tee -a $logFileName
        apt-get autoclean |& tee -a $logFileName
        apt-get clean |& tee -a $logFileName
        appstreamcli refresh --force |& tee -a $logFileName
        apt-file update |& tee -a $logFileName
        sectionBreak
    fi
    if isConnected
    then # Checking for internet connection
        # Internet connection established
        cPrint "YELLOW" "Upgrading software packages." |& tee -a $logFileName
        holdTerminal 2 # Hold for user to read
        apt-get upgrade -y |& tee -a $logFileName

        # Add script actions to script actions array
        scriptActions=( "${scriptActions[@]}" "upgrade" )
        sectionBreak
    else
        apt-get check |& tee -a $logFileName
        apt-get --fix-broken install |& tee -a $logFileName
        dpkg --configure -a |& tee -a $logFileName
        apt-get autoremove -y |& tee -a $logFileName
        apt-get autoclean |& tee -a $logFileName
        apt-get clean |& tee -a $logFileName
        appstreamcli refresh --force |& tee -a $logFileName
        apt-file update |& tee -a $logFileName
        sectionBreak
    fi
    if isConnected
    then # Checking for internet connection
        # Internet connection established
        cPrint "YELLOW" "Running dist upgrade." |& tee -a $logFileName
        holdTerminal 2 # Hold for user to read
        apt-get dist-upgrade -y |& tee -a $logFileName

        # Add script actions to script actions array
        scriptActions=( "${scriptActions[@]}" "dist-upgrade" )
        sectionBreak
    else
        apt-get check |& tee -a $logFileName
        apt-get --fix-broken install |& tee -a $logFileName
        dpkg --configure -a |& tee -a $logFileName
        apt-get autoremove -y |& tee -a $logFileName
        apt-get autoclean |& tee -a $logFileName
        apt-get clean |& tee -a $logFileName
        appstreamcli refresh --force |& tee -a $logFileName
        apt-file update |& tee -a $logFileName
        sectionBreak
    fi
    if isConnected
    then # Checking for internet connection
        # Internet connection established
        cPrint "YELLOW" "Running full upgrade." |& tee -a $logFileName
        holdTerminal 2 # Hold for user to read
        apt-get full-upgrade -y |& tee -a $logFileName

        # Add script actions to script actions array
        scriptActions=( "${scriptActions[@]}" "full-upgrade" )
        sectionBreak
    else
        apt-get check |& tee -a $logFileName
        apt-get --fix-broken install |& tee -a $logFileName
        dpkg --configure -a |& tee -a $logFileName
        apt-get autoremove -y |& tee -a $logFileName
        apt-get autoclean |& tee -a $logFileName
        apt-get clean |& tee -a $logFileName
        appstreamcli refresh --force |& tee -a $logFileName
        apt-file update |& tee -a $logFileName
        sectionBreak
    fi
    if isConnected
    then # Checking for internet connection
        # Internet connection established
        cPrint "YELLOW" "Installing apt-file for apt-file updates." |& tee -a $logFileName
        holdTerminal 2 # Hold for user to read
        apt-get install apt-file -y |& tee -a $logFileName
        holdTerminal 2 # Hold for user to read
        sectionBreak

        cPrint "YELLOW" "Running apt-file update." |& tee -a $logFileName
        holdTerminal 2
        apt-file update |& tee -a $logFileName
        holdTerminal 2 # Hold for user to read

        # Add script actions to script actions array
        scriptActions=( "${scriptActions[@]}" "apt-file-update" )
        sectionBreak
    else
        apt-get check |& tee -a $logFileName
        apt-get --fix-broken install |& tee -a $logFileName
        dpkg --configure -a |& tee -a $logFileName
        apt-get autoremove -y |& tee -a $logFileName
        apt-get autoclean |& tee -a $logFileName
        apt-get clean |& tee -a $logFileName
        appstreamcli refresh --force |& tee -a $logFileName
        apt-file update |& tee -a $logFileName
        sectionBreak
    fi
}

# Function to fix any unmet dependencies and broken installs incase of network interruption
function checkDebugAndRollback(){
    if [ "$1" == '--debug' ]
    then # Check for debug switch
        cPrint "GREEN" "Checking for errors and debugging. Please wait..." |& tee -a $logFileName
    elif [ "$1" == '--network' ]
    then # Check for network switch
        cPrint "GREEN" "Debugging and rolling back some changes due to network interrupt. Please wait..." |& tee -a $logFileName
    fi
    holdTerminal 2 # Hold for user to read

    cPrint "YELLOW"  "Checking for broken/unmet dependencies and fixing broken installs." |& tee -a $logFileName
    holdTerminal 2 # Hold for user to read
    apt-get check |& tee -a $logFileName
    apt-get --fix-broken install |& tee -a $logFileName
    sectionBreak

    cPrint "YELLOW" "Cleaning apt-get cache, disk space and removing unused packages." |& tee -a $logFileName
    holdTerminal 2 # Hold for user to read
    apt-get autoclean -y |& tee -a $logFileName
    apt-get clean -y |& tee -a $logFileName
    apt-get autoremove -y |& tee -a $logFileName
    sectionBreak

    cPrint "YELLOW" "Configuring packages." |& tee -a $logFileName
    holdTerminal 1 # Hold for user to read
    dpkg --configure -a |& tee -a $logFileName
    cPrint "NC" "dpkg package configuration completed." |& tee -a $logFileName
    holdTerminal 2 # Hold for user to read
    sectionBreak

    if [[ "$2" == '--update-upgrade' && "$1" == '--debug' ]]
    then # Check for update-upgrade switch
        # Update system packages and upgrade software packages
        updateAndUpgrade
    fi

    cPrint "YELLOW" "Cleaning apt-get cache, disk space and removing unused packages." |& tee -a $logFileName
    holdTerminal 2 # Hold for user to read
    apt-get autoclean -y |& tee -a $logFileName
    apt-get clean -y |& tee -a $logFileName
    apt-get --fix-broken install |& tee -a $logFileName
    apt-get autoremove -y |& tee -a $logFileName
    sectionBreak

    cPrint "YELLOW" "Updating AppStream cache." |& tee -a $logFileName
    holdTerminal 2 # Hold for user to read
    appstreamcli refresh --force |& tee -a $logFileName
    sectionBreak

    cPrint "GREEN" "Checking and debugging completed successfuly!!" |& tee -a $logFileName
    sectionBreak
}

# Function to exit script with custom coloured message
function exitScript(){
  # Display exit message
    cPrint "RED" "Exiting script...." |& tee -a $logFileName
    holdTerminal 1 # Hold for user to read

    if [ "$1" == '--end' ]
    then # Check for --end switch
        if [ "$setupCancelled" -eq 0 ]
        then # Check and debug any errors
            checkDebugAndRollback --debug --update-upgrade

            ${clear} # Clear terminal

            cd ~ || exit # Change to home directory
            cPrint "YELLOW" "You can find this scripts\' logs in \e[1;31m$(pwd)\e[0m named $logFileName"
            cPrint "GREEN" "\n Type: \e[1;31mcat $scriptName\e[0m to view the logs in terminal"
            holdTerminal 5 # Hold for user to read
        fi
        ${clear} # Clear terminal
        echo ""; displayScriptInfo # Display script information

        # Get script execution time
        endTime=`date +%s` # Get start time
        executionTimeInSeconds=$((endTime-startTime))
        # Calculate time in days:hours:minutes:seconds
        formatTime $executionTimeInSeconds

        # Draw logo
        printf "\n\n       __   __\n      |  | |  |  ___\n      |  | |  | /  /\n    __|  | |  |/  /\n  /  _   | |     <\n |  (_|  | |  |\  \ \n  \______| |__| \__\ \n\n "
        cPrint "YELLOW" "Script execution time : $totalExecutionTime \n"

        if [ "$setupCancelled" -eq 0 ]
        then
            # Display exit message
            cPrint "RED" "Script completed successfuly...\n\n" |& tee -a $logFileName
        else
          # Display exit message
          cPrint "RED" "Exited script...\n\n" |& tee -a $logFileName
        fi
    elif [ "$1" == '--connectionFailure' ]
    then
        cPrint "RED" "\n\n This script requires a stable internet connection to work fully!!" |& tee -a $logFileName
        cPrint "NC" "Please check your connection settings and re-run the script.\n" |& tee -a $logFileName

        if [ "$2" == '--rollback' ]
        then # Check for rollback switch
          # Check for and fix any broken installs or unmet dependencies
          checkDebugAndRollback --network
        fi
    fi
    exit 0 # Exit script
}

# Function to check current desktop environment
function checkForDefaultDesktopEnvironment(){
    if [ "$1" != '--noResponse' ]
    then
        cPrint "YELLOW" "Checking for default desktop environment.." |& tee -a $logFileName
        holdTerminal 2 # Hold for user to read
    fi
    if [ "$XDG_CURRENT_DESKTOP" = "" ]
    then # Check for installed  Desktop environments
        currentDesktopEnvironment=$(echo "$XDG_DATA_DIRS" | sed 's/.*\(gnome\|kde\|xfce\|lxde\|lxqt\|cinnamon\|mate\|budgie\|enlightenment\|kodi\).*/\1/')
    else # Get XDG current desktop
        currentDesktopEnvironment=$XDG_CURRENT_DESKTOP
    fi
    # Check if desktop environment was found
    if [ -z "$currentDesktopEnvironment" ]
    then # (Variable empty) - Desktop environment not found
        xSessions=$(ls -l $xSessionsPath) # Get all xSessions
        if [ -z "$xSessions" ]
        then
            cPrint "GREEN" "No default display manager found!!" |& tee -a $logFileName
            holdTerminal 1 # Hold for user to read
        else
            cPrint "GREEN" "No default display manager found!!" |& tee -a $logFileName
            cPrint "GREEN" "The below desktop environment xsession files were found:\n$xSessions"
            holdTerminal 4 # Hold for user to read
        fi
    else
        if [ "$1" != '--noResponse' ]
        then # Display choice
            cPrint "GREEN" "Current default : $currentDesktopEnvironment" |& tee -a $logFileName
            holdTerminal 1 # Hold for user to read
        fi
    fi
}

# Function to get a list of all installed desktop environment
function getAllInstalledDesktopEnvironments(){
    foundGNOMEInstalled=0; foundKDEPLASMAInstalled=0;  foundXFCEInstalled=0;
    foundLXDEInstalled=0; foundLXQTInstalled=0; foundCINNAMONInstalled=0;
    foundMATEInstalled=0; foundBUDGIEInstalled=0; foundENLIGHTENMENTInstalled=0;
    foundKODIInstalled=0;

    # Numbers the list of installed desktop environment
    local -i listCount=0

    unset uninstallationList installedDesktopEnvironments
    unset listOfInstalledDesktopEnvironments

    # Get all installed desktop environments
    installedDesktopEnvironments=$(ls -l /usr/share/xsessions/)

    # Variable to store a list of all installed desktop environments
    listOfInstalledDesktopEnvironments="" |& tee -a $logFileName

    # Checking for individual desktop environment
    if [[ $installedDesktopEnvironments == *"gnome.desktop"*
      || $installedDesktopEnvironments == *"gnome-classic.desktop"*
      || $installedDesktopEnvironments == *"gnome-flashback-metacity.desktop"*
      || $installedDesktopEnvironments == *"gnome-xorg.desktop"* ]]
    then
        foundGNOMEInstalled=$[foundGNOMEInstalled + 1]
        listCount=$[listCount+1] # Update list count
        # Adding GNOME to list of installed desktop environments
        listOfInstalledDesktopEnvironments="${listOfInstalledDesktopEnvironments} \n\t$listCount. GNOME Desktop."
        uninstallationList="${uninstallationList}gnome "
    fi
    if [[ $installedDesktopEnvironments == *"plasma.desktop"* ]]
    then
        foundKDEPLASMAInstalled=$[foundKDEPLASMAInstalled + 1]
        listCount=$[listCount+1] # Update list count
        # Adding KDE PLASMA to list of installed desktop environments
        listOfInstalledDesktopEnvironments="${listOfInstalledDesktopEnvironments} \n\t$listCount. KDE Plasma Desktop."
        uninstallationList="${uninstallationList}kde "
    fi
    if [[ $installedDesktopEnvironments == *"xfce.desktop"* ]]
    then
        foundXFCEInstalled=$[foundXFCEInstalled + 1]
        listCount=$[listCount+1] # Update list count
        # Adding XFCE to list of installed desktop environments
        listOfInstalledDesktopEnvironments="${listOfInstalledDesktopEnvironments} \n\t$listCount. XFCE Desktop."
        uninstallationList="${uninstallationList}xfce "
    fi
    if [[ $installedDesktopEnvironments == *"lxde.desktop"*
      || $installedDesktopEnvironments == *"LXDE.desktop"* ]]
    then
        foundLXDEInstalled=$[foundLXDEInstalled + 1]
        listCount=$[listCount+1] # Update list count
        # Adding LXDE to list of installed desktop environments
        listOfInstalledDesktopEnvironments="${listOfInstalledDesktopEnvironments} \n\t$listCount. LXDE Desktop."
        uninstallationList="${uninstallationList}lxde "
    fi
    if [[ $installedDesktopEnvironments == *"lxqt.desktop"* ]]
    then
        foundLXQTInstalled=$[foundLXQTInstalled + 1]
        listCount=$[listCount+1] # Update list count
        # Adding LXQT to list of installed desktop environments
        listOfInstalledDesktopEnvironments="${listOfInstalledDesktopEnvironments} \n\t$listCount. LXQT Desktop."
        uninstallationList="${uninstallationList}lxqt "
    fi
    if [[ $installedDesktopEnvironments == *"cinnamon.desktop"* ]]
    then
        foundCINNAMONInstalled=$[foundCINNAMONInstalled + 1]
        listCount=$[listCount+1] # Update list count
        # Adding CINNAMON to list of installed desktop environments
        listOfInstalledDesktopEnvironments="${listOfInstalledDesktopEnvironments} \n\t$listCount. CINNAMON Desktop."
        uninstallationList="${uninstallationList}cinnamon "
    fi
    if [[ $installedDesktopEnvironments == *"mate.desktop"* ]]
    then
        foundMATEInstalled=$[foundMATEInstalled + 1]
        listCount=$[listCount+1] # Update list count
        # Adding MATE to list of installed desktop environments
        listOfInstalledDesktopEnvironments="${listOfInstalledDesktopEnvironments} \n\t$listCount. MATE Desktop."
        uninstallationList="${uninstallationList}mate "
    fi
    if [[ $installedDesktopEnvironments == *"budgie-desktop.desktop"* ]]
    then
        foundBUDGIEInstalled=$[foundBUDGIEInstalled + 1]
        listCount=$[listCount+1] # Update list count
        # Adding BUDGIE to list of installed desktop environments
        listOfInstalledDesktopEnvironments="${listOfInstalledDesktopEnvironments} \n\t$listCount. BUDGIE Desktop."
        uninstallationList="${uninstallationList}budgie "
    fi
    if [[ $installedDesktopEnvironments == *"enlightenment.desktop"* ]]
    then
        foundENLIGHTENMENTInstalled=$[foundENLIGHTENMENTInstalled + 1]
        listCount=$[listCount+1] # Update list count
        # Adding ENLIGHTENMENT to list of installed desktop environments
        listOfInstalledDesktopEnvironments="${listOfInstalledDesktopEnvironments} \n\t$listCount. ENLIGHTENMENT Desktop."
        uninstallationList="${uninstallationList}enlightenment "
    fi
    if [[ $installedDesktopEnvironments == *"kodi.desktop"* ]]
    then
        foundKODIInstalled=$[foundKODIInstalled + 1]
        listCount=$[listCount+1] # Update list count
        # Adding KODI to list of installed desktop environments
        listOfInstalledDesktopEnvironments="${listOfInstalledDesktopEnvironments} \n\t$listCount. KODI Desktop."
        uninstallationList="${uninstallationList}kodi "
    fi

    # Sum up all found desktop environments
    noOfInstalledDesktopEnvironments=$((foundGNOMEInstalled
        +foundKDEPLASMAInstalled+foundXFCEInstalled+foundLXDEInstalled
        +foundLXQTInstalled+foundCINNAMONInstalled+foundMATEInstalled
        +foundBUDGIEInstalled+foundENLIGHTENMENTInstalled+foundKODIInstalled))

    if [ "$listCount" -gt 1 ]
    then # More that one desktop environment found
        listCount=$[listCount+1] # Update list count
        listOfInstalledDesktopEnvironments="${listOfInstalledDesktopEnvironments} \n\t$listCount. Uninstall all desktop environments." # Add option to uninstall all at once
    fi

    # Add option to cancel uninstallation
    listCount=$[listCount+1] # Update list count
    listOfInstalledDesktopEnvironments="${listOfInstalledDesktopEnvironments} \n\t$listCount. Cancel."

    # Adding line break after list
    listOfInstalledDesktopEnvironments="${listOfInstalledDesktopEnvironments} \n"
    if [ "$noOfInstalledDesktopEnvironments" -gt 0 ]
    then # 1 or more desktop environment installed
        if [ "$1" == '--displayList' ]
        then
            cPrint "GREEN" "Found a total of $noOfInstalledDesktopEnvironments installed desktop environments." |& tee -a $logFileName
            # Display list of installed desktop environments
            cPrint "YELLOW" "$listOfInstalledDesktopEnvironments"  |& tee -a $logFileName
            holdTerminal 1 # Hold for user to read
        fi
    fi
}

# Function to check the set default desktop environment incase of more
# that one desktop environment
function checkSetDefaultDesktopEnvironment(){
    cPrint "YELLOW" "Checking for the default desktop environment." |& tee -a $logFileName
    holdTerminal 1 # Hold for user to read
    # Display set default desktop environment
    cat /etc/X11/default-display-manager |& tee -a $logFileName
}

# Function to query if user wants to install another desktop environment
# after installing the previous
function queryInstallAnotherDesktopEnvironment(){
    while true
    do # Start infinite loop
        ${clear} # Clear terminal

        # Prompt user to set GNOME Desktop as default
        cPrint "YELLOW" "Would you like to install another desktop environment?\n\t1. Y (Yes) - to install another.\n\t2. N (No) to cancel." |& tee -a $logFileName
        read -p ' option: ' queryInstChoice
        queryInstChoice=${queryInstChoice,,} # Convert to lowercase
        # Display choice
        cPrint "GREEN" " You chose : $queryInstChoice" |& tee -a $logFileName

        if  [[ "$queryInstChoice" == 'yes' || "$queryInstChoice" == 'y'
              || "$queryInstChoice" == '1' ]]
        then # Option : Yes
            return $(true) # Exit loop returning true
        elif [[ "$queryInstChoice" == 'no' || "$queryInstChoice" == 'n'
              || "$queryInstChoice" == '2' ]]
        then # Option : No
            ${clear} # Clear terminal
            return $(false) # Exit loop returning false
        else
            # Invalid entry
            cPrint "GREEN" "Invalid entry!! Please try again." |& tee -a $logFileName
        fi
        sleep 1 # Hold loop
    done
}

# Function to install X Window Server (xorg)
function installXWindowServer(){
    ${clear} # Clear terminal

    # Check if XServer is installed
    check=`dpkg -l |grep xserver-xorg-core`

    # Check for command outp.ut
    if [[ "$check" == *"ii  xserver-xorg-core"*
          || "$check" == *"Xorg X server - core server"* ]]
    then # XServer found
        if [ $XServerInstalled -eq 0 ]
        then
            # Prevent message showing many times during loop
            if [ "$checkedForXServer" -eq 0 ]
            then
                # Display below message only once during runtime
                cPrint "GREEN" "Checked for XServer installation.\n ...XServer is already installed."
            fi
            XServerInstalled=1 # Set X Server installed to true.
            checkedForXServer=1
            holdTerminal 3 # Hold for user to read
        fi
    else # XServer not found
        # Checking for internet connection before continuing
        if isConnected
        then # Internet connection Established
            cPrint "YELLOW" "\n\n Installing XORG. This may take a while depending on your internet connection. Please wait..." |& tee -a $logFileName
            holdTerminal 5 # Hold for user to read
            # Install X window Server
            apt-get install xorg -y |& tee -a $logFileName
            holdTerminal 2 # Hold for user to read
            # Add script actions to script actions array
            scriptActions=( "${scriptActions[@]}" "install-xorg" )
            sectionBreak
        else
          exitScript --connectionFailure # Exit script on connection failure
        fi
    fi
}

# Function to install GNOME Desktop environment
function installGNOMEDesktop(){

    if [ "$foundGNOMEInstalled" -eq 0 ]
    then # Found

        installXWindowServer # Install X Window Server
        ${clear} # Clear terminal

        # Checking for internet connection before continuing
        if isConnected
        then # Internet connection Established
            cPrint "YELLOW" "\n\n Installing GNOME. This may take a while depending on your internet connection. Please wait..." |& tee -a $logFileName
            holdTerminal 5 # Hold for user to read
            if [ "$1" == '--y' ]
            then # Check for yes switch to install without confirmation
            # Install full GNOME with confirmation
                apt-get install gnome -y |& tee -a $logFileName
                apt-get install task-gnome-desktop -y |& tee -a $logFileName
                holdTerminal 2 # Hold for user to read
            else # Install full GNOME without confirmation
                apt-get install gnome task-gnome-desktop |& tee -a $logFileName
                holdTerminal 2 # Hold for user to read
            fi

            # Add script actions to script actions array
            scriptActions=( "${scriptActions[@]}" "install-desktop-gnome" )
            cPrint "YELLOW" "\n\n Installing alacarte menu editor for GNOME." |& tee -a $logFileName
            holdTerminal 4 # Hold for user to read

            # Install alacarte
            apt-get install alacarte |& tee -a $logFileName
            holdTerminal 2 # Hold for user to read

            # Add script actions to script actions array
            scriptActions=( "${scriptActions[@]}" "install-alacarte" )

            cPrint "GREEN" "GNOME installation complete." |& tee -a $logFileName
            holdTerminal 1 # Hold for user to read

            cPrint "YELLOW" "Checking if gdm3 is installed. If not it will be installed." |& tee -a $logFileName
            holdTerminal 4 # Hold for user to read

            # Install gdm3 if id does not exist
            apt-get install gdm3 |& tee -a $logFileName
            holdTerminal 2 # Hold for user to read

            # Check for GNOME setDefault switch
            if [ "$2" == '--setDefault' ]
            then
                cPrint "YELLOW" "Setting GNOME as default desktop environment." |& tee -a $logFileName
                holdTerminal 4 # Hold for user to read
                cPrint "YELLOW" "Please select gdm3 when prompted." |& tee -a $logFileName
                holdTerminal 4 # Hold for user to read
                dpkg-reconfigure gdm3 |& tee -a $logFileName

                # Check for set default desktop environment
                checkSetDefaultDesktopEnvironment

            else # Let user decide
                while true
                do
                    # Prompt user to set GNOME Desktop as default
                    cPrint "YELLOW" "Would you like to set GNOME as yout default desktop environment?\n\t1. Y (Yes) - to set default.\n\t2. N (No) to cancel or skip." |& tee -a $logFileName
                    read -p ' option: ' dfChoice
                    dfChoice=${dfChoice,,} # Convert to lowercase

                    # Display choice
                    cPrint "GREEN" " You chose : $dfChoice" |& tee -a $logFileName

                    if  [[ "$dfChoice" == 'yes' || "$dfChoice" == 'y'
                        || "$dfChoice" == '1' ]]
                    then # Option : Yes
                        cPrint "YELLOW" "Setting GNOME as default desktop environment." |& tee -a $logFileName
                        holdTerminal 4 # Hold for user to read
                        dpkg-reconfigure gdm3 |& tee -a $logFileName

                        # Check for set default desktop environment
                        checkSetDefaultDesktopEnvironment
                        break # Break from loop
                    elif  [[ "$dfChoice" == 'no' || "$dfChoice" == 'n'
                          || "$dfChoice" == '2' ]]
                    then # Option : No
                        cPrint "NC" "Skipped..." |& tee -a $logFileName
                        break # Break from loop
                    else
                      # Invalid entry
                      cPrint "GREEN" "Invalid entry!! Please try again." |& tee -a $logFileName
                    fi
                    sleep 1 # Hold loop
                done
            fi

            # Set GNOME installed to true
            justInstalledGNOME=$[justInstalledGNOME + 1]
            cPrint "GREEN" "Your GNOME Desktop is all set." |& tee -a $logFileName
            sectionBreak
        else
            exitScript --connectionFailure # Exit script on connection failure
        fi
    else
        ${clear} # Clear terminal
        cPrint "GREEN" "GNOME desktop is already installed." |& tee -a $logFileName
        holdTerminal 3 # Hold for user to read
        sectionBreak
    fi
}

# Function to install KDE PLASMA Desktop environment
function installKDEPlasmaDesktop(){

    if [ "$foundKDEPLASMAInstalled" -eq 0 ]
    then # Found

        installXWindowServer # Install X Window Server
        ${clear} # Clear terminal

        # Checking for internet connection before continuing
        if isConnected
        then # Internet connection Established
            cPrint "YELLOW" "\n\n Installing KDE PLASMA Desktop. This may take a while depending on your internet connection. Please wait..." |& tee -a $logFileName
            holdTerminal 5 # Hold for user to read

            if [ "$1" == '--y' ]
            then # Check for yes switch to install without confirmation
            # Install KDE PLASMA Desktop without confirmation
                apt-get install kde-full -y |& tee -a $logFileName
                apt-get install task-kde-desktop -y |& tee -a $logFileName
                holdTerminal 2 # Hold for user to read
            else
                # Install KDE PLASMA Desktop with confirmation
                apt-get install kde-full |& tee -a $logFileName
                apt-get install task-kde-desktop |& tee -a $logFileName
                holdTerminal 2 # Hold for user to read
            fi

            # Add script actions to script actions array
            scriptActions=( "${scriptActions[@]}" "install-desktop-kde" )

            # Set KDE PLASMA Desktop installed to true
            justInstalledKDEPLASMA=$[justInstalledKDEPLASMA + 1]
            cPrint "GREEN" "Your KDE PLASMA Desktop is all set." |& tee -a $logFileName

            # Check for set default desktop environment
            checkSetDefaultDesktopEnvironment
            sectionBreak
        else
            exitScript --connectionFailure # Exit script on connection failure
        fi
    else
        ${clear} # Clear terminal
        cPrint "GREEN" "KDE PLASMA desktop is already installed." |& tee -a $logFileName
        holdTerminal 3 # Hold for user to read
        sectionBreak
    fi
}

# Function to install XFCE Desktop environment
function installXFCEDesktop(){

    if [ "$foundXFCEInstalled" -eq 0 ]
    then # Found

        installXWindowServer # Install X Window Server
        ${clear} # Clear terminal

        # Checking for internet connection before continuing
        if isConnected
        then # Internet connection Established
            cPrint "YELLOW" "\n\n Installing XFCE Desktop. This may take a while depending on your internet connection. Please wait..." |& tee -a $logFileName
            holdTerminal 5 # Hold for user to read
            if [ "$1" == '--y' ]
            then # Check for yes switch to install without confirmation
                # Install XFCE4 Desktop with confirmation
                apt-get install xfce4 -y |& tee -a $logFileName
                apt-get install task-xfce-desktop -y |& tee -a $logFileName
                apt-get install xfce.desktop -y |& tee -a $logFileName
                holdTerminal 2 # Hold for user to read
            else
                # Install XFCE4 Desktop without confirmation
                apt-get install xfce4 -y |& tee -a $logFileName
                apt-get install task-xfce-desktop |& tee -a $logFileName
                apt-get install xfce.desktop |& tee -a $logFileName
                holdTerminal 2 # Hold for user to read
            fi

            # Add script actions to script actions array
            scriptActions=( "${scriptActions[@]}" "install-desktop-xfce" )

            # Set XFCE Desktop installed to true
            justInstalledXFCE=$[justInstalledXFCE + 1]
            cPrint "GREEN" "Your XFCE Desktop is all set." |& tee -a $logFileName

            # Check for set default desktop environment
            checkSetDefaultDesktopEnvironment
            sectionBreak
        else
            exitScript --connectionFailure # Exit script on connection failure
        fi
    else
        ${clear} # Clear terminal
        cPrint "GREEN" "XFCE desktop is already installed." |& tee -a $logFileName
        holdTerminal 3 # Hold for user to read
        sectionBreak
    fi
}

# Function to install LXDE Desktop environment
function installLXDEDesktop(){

    if [ "$foundLXDEInstalled" -eq 0 ]
    then # Found

        installXWindowServer # Install X Window Server
        ${clear} # Clear terminal

        # Checking for internet connection before continuing
        if isConnected
        then # Internet connection Established
            cPrint "YELLOW" "\n\n Installing LXDE Desktop. This may take a while depending on your internet connection. Please wait..." |& tee -a $logFileName
            holdTerminal 5 # Hold for user to read
            if [ "$1" == '--y' ]
            then # Check for yes switch to install without confirmation
                # Install LXDE Desktop environment with confirmation
                apt-get install lxde -y |& tee -a $logFileName
                apt-get install task-lxde-desktop -y |& tee -a $logFileName
                apt-get install lxde.desktop lxdm -y |& tee -a $logFileName
                holdTerminal 2 # Hold for user to read
            else
                # Install LXDE Desktop environment without confirmation
                apt-get install lxde task-lxde-desktop -y |& tee -a $logFileName
                apt-get install lxde.desktop lxdm |& tee -a $logFileName
                holdTerminal 2 # Hold for user to read
            fi

            # Add script actions to script actions array
            scriptActions=( "${scriptActions[@]}" "install-desktop-lxde" )

            # Set LXDE Desktop installed to true
            justInstalledLXDE=$[justInstalledLXDE + 1]
            cPrint "GREEN" "Your LXDE Desktop is all set." |& tee -a $logFileName

            # Check for set default desktop environment
            checkSetDefaultDesktopEnvironment
            sectionBreak
        else
            exitScript --connectionFailure # Exit script on connection failure
        fi
    else
        ${clear} # Clear terminal
        cPrint "GREEN" "LXDE desktop is already installed." |& tee -a $logFileName
        holdTerminal 3 # Hold for user to read
        sectionBreak
    fi
}

# Function to install LXQT Desktop environment
function installLXQTDesktop(){

    if [ "$foundLXQTInstalled" -eq 0 ]
    then # Found

        installXWindowServer # Install X Window Server
        ${clear} # Clear terminal

        # Checking for internet connection before continuing
        if isConnected
        then # Internet connection Established
            cPrint "YELLOW" "\n\n Installing LXQT Desktop. This may take a while depending on your internet connection. Please wait..." |& tee -a $logFileName
            holdTerminal 5 # Hold for user to read
            if [ "$1" == '--y' ]
            then # Check for yes switch to install without confirmation
                # Install LXQT Desktop environment with confirmation
                apt-get install lxqt sddm -y |& tee -a $logFileName
                apt-get install task-lxqt-desktop -y |& tee -a $logFileName
                apt-get install lxqt.desktop -y |& tee -a $logFileName
                holdTerminal 2 # Hold for user to read
            else
                # Install LXQT Desktop environment without confirmation
                apt-get install lxqt sddm |& tee -a $logFileName
                apt-get install task-lxqt-desktop |& tee -a $logFileName
                apt-get install lxqt.desktop |& tee -a $logFileName
                holdTerminal 2 # Hold for user to read
            fi

            # Add script actions to script actions array
            scriptActions=( "${scriptActions[@]}" "install-desktop-lxqt" )

            # Set LXQT Desktop installed to true
            justInstalledLXQT=$[justInstalledLXQT + 1]
            cPrint "GREEN" "Your LXQT Desktop is all set." |& tee -a $logFileName

            # Check for set default desktop environment
            checkSetDefaultDesktopEnvironment
            sectionBreak
        else
            exitScript --connectionFailure # Exit script on connection failure
        fi
    else
        ${clear} # Clear terminal
        cPrint "GREEN" "LXQT desktop is already installed." |& tee -a $logFileName
        holdTerminal 3 # Hold for user to read
        sectionBreak
    fi
}

# Function to install CINNAMON Desktop environment
function installCinnamonDesktop(){

    if [ "$foundCINNAMONInstalled" -eq 0 ]
    then # Found

        installXWindowServer # Install X Window Server
        ${clear} # Clear terminal

        # Checking for internet connection before continuing
        if isConnected
        then # Internet connection Established
            cPrint "YELLOW" "\n\n Installing CINNAMON Desktop. This may take a while depending on your internet connection. Please wait..." |& tee -a $logFileName
            holdTerminal 5 # Hold for user to read

            if [ "$1" == '--y' ]
            then # Check for yes switch to install without confirmation
                # Install ENLIGHTENMENT Desktop environment with confirmation
                apt-get install cinnamon-desktop-environment -y |& tee -a $logFileName
                apt-get install task-cinnamon-desktop -y |& tee -a $logFileName
                holdTerminal 2 # Hold for user to read
            else
                # Install ENLIGHTENMENT Desktop environment without confirmation
                apt-get install cinnamon-desktop-environment |& tee -a $logFileName
                apt-get install task-cinnamon-desktop |& tee -a $logFileName
                holdTerminal 2 # Hold for user to read
            fi

            # Add script actions to script actions array
            scriptActions=( "${scriptActions[@]}" "install-desktop-cinnamon" )

            # Set CINNAMON Desktop installed to true
            justInstalledCINNAMON=$[justInstalledCINNAMON + 1]
            cPrint "GREEN" "Your CINNAMON Desktop is all set." |& tee -a $logFileName

            # Check for set default desktop environment
            checkSetDefaultDesktopEnvironment
            sectionBreak
        else
            exitScript --connectionFailure # Exit script on connection failure
        fi
    else
        ${clear} # Clear terminal
        cPrint "GREEN" "CINNAMON desktop is already installed." |& tee -a $logFileName
        holdTerminal 3 # Hold for user to read
        sectionBreak
    fi
}

# Function to install MATE Desktop environment
function installMateDesktop(){

    if [ "$foundMATEInstalled" -eq 0 ]
    then # Found

        installXWindowServer # Install X Window Server
        ${clear} # Clear terminal

        # Checking for internet connection before continuing
        if isConnected
        then # Internet connection Established
            cPrint "YELLOW" "\n\n Installing MATE Desktop. This may take a while depending on your internet connection. Please wait..." |& tee -a $logFileName
            holdTerminal 5 # Hold for user to read
            if [ "$1" == '--y' ]
            then # Check for yes switch to install without confirmation
                # Install MATE Desktop environment with confirmation
                apt-get install mate-desktop-environment -y |& tee -a $logFileName
                apt-get install task-mate-desktop -y |& tee -a $logFileName
                holdTerminal 2 # Hold for user to read

                cPrint "YELLOW" "\n\n Installing MATE Extras..." |& tee -a $logFileName
                holdTerminal 2 # Hold for user to read

                # Install MATE Desktop environment Extras
                apt-get install mate-desktop-environment-extras -y |& tee -a $logFileName
                holdTerminal 2 # Hold for user to read
            else
                # Install MATE Desktop environment without confirmation
                apt-get install mate-desktop-environment |& tee -a $logFileName
                apt-get install task-mate-desktop |& tee -a $logFileName
                holdTerminal 2 # Hold for user to read

                cPrint "YELLOW" "\n\n Installing MATE Extras..." |& tee -a $logFileName
                holdTerminal 2 # Hold for user to read

                # Install MATE Desktop environment Extras
                apt-get install mate-desktop-environment-extras |& tee -a $logFileName
                holdTerminal 2 # Hold for user to read
            fi

            # Add script actions to script actions array
            scriptActions=( "${scriptActions[@]}" "install-desktop-mate" )

            # Set MATE Desktop installed to true
            justInstalledMATE=$[justInstalledMATE + 1]
            cPrint "GREEN" "Your MATE Desktop is all set." |& tee -a $logFileName

            # Check for set default desktop environment
            checkSetDefaultDesktopEnvironment
            sectionBreak
        else
            exitScript --connectionFailure # Exit script on connection failure
        fi
    else
        ${clear} # Clear terminal
        cPrint "GREEN" "MATE  desktop is already installed." |& tee -a $logFileName
        holdTerminal 3 # Hold for user to read
        sectionBreak
    fi
}

# Function to install BUDGIE Desktop environment
function installBudgieDesktop(){

    if [ "$foundBUDGIEInstalled" -eq 0 ]
    then # Found

        installXWindowServer # Install X Window Server
        ${clear} # Clear terminal

        # Checking for internet connection before continuing
        if isConnected
        then # Internet connection Established
            cPrint "YELLOW" "\n\n Installing BUDGIE Desktop. This will install GNOME as a dependencys on it.\n This may take a while depending on your internet connection. Please wait..." |& tee -a $logFileName
            holdTerminal 6 # Hold for user to read
            if [ "$1" == '--y' ]
            then # Check for yes switch to install without confirmation
                # Install BUDGIE Desktop environment with confirmation
                apt-get install budgie-desktop -y |& tee -a $logFileName
                apt-get install budgie-indicator-applet -y |& tee -a $logFileName
                holdTerminal 2 # Hold for user to read

                # Install BUDGIE Desktop environment with confirmation
                apt-get install budgie.desktop -y |& tee -a $logFileName
                holdTerminal 2 # Hold for user to read
            else
                # Install BUDGIE Desktop environment without confirmation
                apt-get install budgie-desktop |& tee -a $logFileName
                apt-get install budgie-indicator-applet |& tee -a $logFileName
                holdTerminal 2 # Hold for user to read

                # Install BUDGIE Desktop environment without confirmation
                apt-get install budgie.desktop |& tee -a $logFileName
                holdTerminal 2 # Hold for user to read
            fi

            # Add script actions to script actions array
            scriptActions=( "${scriptActions[@]}" "install-desktop-budgie" )

            # Set BUDGIE Desktop installed to true
            justInstalledBUDGIE=$[justInstalledBUDGIE + 1]
            cPrint "GREEN" "Your BUDGIE Desktop is all set." |& tee -a $logFileName

            # Check for set default desktop environment
            checkSetDefaultDesktopEnvironment
            sectionBreak
        else
            exitScript --connectionFailure # Exit script on connection failure
        fi
    else
        ${clear} # Clear terminal
        cPrint "GREEN" "BUDGIE  desktop is already installed." |& tee -a $logFileName
        holdTerminal 3 # Hold for user to read
        sectionBreak
    fi
}

# Function to install ENLIGHTENMENT Desktop environment
function installEnlightenmentDesktop(){

    if [ "$foundENLIGHTENMENTInstalled" -eq 0 ]
    then # Found

        installXWindowServer # Install X Window Server
        ${clear} # Clear terminal

        # Checking for internet connection before continuing
        if isConnected
        then # Internet connection Established
            cPrint "YELLOW" "\n\n Installing ENLIGHTENMENT Desktop dependencies." |& tee -a $logFileName
            holdTerminal 3 # Hold for user to read
            apt-get install gcc g++ check libssl-dev -y |& tee -a $logFileName
            apt-get install libsystemd-dev libjpeg-dev -y |& tee -a $logFileName
            apt-get install libglib2.0-dev -y |& tee -a $logFileName
            apt-get install libgstreamer1.0-dev -y |& tee -a $logFileName
            apt-get install libluajit-5.1-dev -y |& tee -a $logFileName
            apt-get install libfreetype6-dev -y |& tee -a $logFileName
            holdTerminal 2 # Hold for user to read

            apt-get install libfontconfig1-dev -y |& tee -a $logFileName
            apt-get install libfribidi-dev libx11-dev -y |& tee -a $logFileName
            apt-get install libxext-dev libxrender-dev -y |& tee -a $logFileName
            apt-get install libgl1-mesa-dev libgif-dev -y |& tee -a $logFileName
            apt-get install libtiff5-dev libpoppler-dev -y |& tee -a $logFileName
            holdTerminal 2 # Hold for user to read

            apt-get install libpoppler-cpp-dev -y |& tee -a $logFileName
            libspectre-dev libraw-dev librsvg2-dev -y |& tee -a $logFileName
            libudev-dev libmount-dev libdbus-1-dev -y |& tee -a $logFileName
            libpulse-dev libsndfile1-dev -y |& tee -a $logFileName
            holdTerminal 2 # Hold for user to read

            apt-get install libxcursor-dev -y |& tee -a $logFileName
            apt-get install libxcomposite-dev -y |& tee -a $logFileName
            apt-get install libxinerama-dev -y |& tee -a $logFileName
            apt-get install libxrandr-dev -y |& tee -a $logFileName
            apt-get install libxtst-dev libxss-dev -y |& tee -a $logFileName
            apt-get install libbullet-dev -y |& tee -a $logFileName
            apt-get install libgstreamer-plugins-base1.0-dev -y |& tee -a $logFileName
            apt-get install doxygen git -y |& tee -a $logFileName
            holdTerminal 2 # Hold for user to read

            printf "\n"; cPrint "YELLOW" "Installing ENLIGHTENMENT Desktop. This may take a while depending on your internet connection. Please wait..." |& tee -a $logFileName
            holdTerminal 5 # Hold for user to read
            if [ "$1" == '--y' ]
            then # Check for yes switch to install without confirmation
                # Install ENLIGHTENMENT Desktop environment with confirmation
                apt-get install enlightenment -y |& tee -a $logFileName
                holdTerminal 2 # Hold for user to read
            else
                # Install ENLIGHTENMENT Desktop environment without confirmation
                apt-get install enlightenment |& tee -a $logFileName
                holdTerminal 2 # Hold for user to read
            fi

            # Add script actions to script actions array
            scriptActions=( "${scriptActions[@]}" "install-desktop-enlightenment" )

            # Set ENLIGHTENMENT Desktop installed to true
            justInstalledENLIGHTENMENT=$[justInstalledENLIGHTENMENT + 1]
            cPrint "GREEN" "Your ENLIGHTENMENT Desktop is all set." |& tee -a $logFileName

            # Check for set default desktop environment
            checkSetDefaultDesktopEnvironment
            sectionBreak
        else
            exitScript --connectionFailure # Exit script on connection failure
        fi
    else
        ${clear} # Clear terminal
        cPrint "GREEN" "ENLIGHTENMENT  desktop is already installed." |& tee -a $logFileName
        holdTerminal 3 # Hold for user to read
        sectionBreak
    fi
}

# Function to install KODI Desktop environment
function installKodiDesktop(){

    if [ "$foundKODIInstalled" -eq 0 ]
    then # Found

        installXWindowServer # Install X Window Server
        ${clear} # Clear terminal

        # Checking for internet connection before continuing
        if isConnected
        then # Internet connection Established
            cPrint "YELLOW" "Installing KODI Desktop. This may take a while depending on your internet connection. Please wait..." |& tee -a $logFileName
            holdTerminal 5 # Hold for user to read
            if [ "$1" == '--y' ]
            then # Check for yes switch to install without confirmation
                # Install KODI Desktop environment with confirmation
                apt-get install kodi -y |& tee -a $logFileName
                holdTerminal 2 # Hold for user to read
            else
                # Install KODI Desktop environment without confirmation
                apt-get install kodi |& tee -a $logFileName
                holdTerminal 2 # Hold for user to read
            fi

            # Add script actions to script actions array
            scriptActions=( "${scriptActions[@]}" "install-desktop-kodi" )

            # Set KODI Desktop installed to true
            justInstalledKODI=$[justInstalledKODI + 1]
            cPrint "GREEN" "Your KODI Desktop is all set." |& tee -a $logFileName

            # Check for set default desktop environment
            checkSetDefaultDesktopEnvironment
            sectionBreak
        else
            exitScript --connectionFailure # Exit script on connection failure
        fi
    else
        ${clear} # Clear terminal
        cPrint "GREEN" "KODI  desktop is already installed." |& tee -a $logFileName
        holdTerminal 3 # Hold for user to read
        sectionBreak
    fi
}

# Function to install all desktop environments
function installAllDesktopEnvironments(){
    # Install all desktop environments
    cPrint "PURPLE" "\n\n Installing all $numberOfDesktopEnvironments desktop environments. This may take time depending on your internet connection. Please wait!\n"
    holdTerminal 4 # Hold for user to read
    installKDEPlasmaDesktop --y # Install KDE PLASMA Desktop
    installXFCEDesktop --y # Install XFCE Desktop
    installLXDEDesktop --y # Install LXDE Desktop
    installLXQTDesktop --y # Install LXQT Desktop
    installCinnamonDesktop --y # Install CINNAMON Desktop
    installMateDesktop --y # Install MATE Desktop
    installBudgieDesktop --y # Install BUDGIE Desktop
    installEnlightenmentDesktop --y # Install ENLIGHTENMENT Desktop
    installKodiDesktop --y # Install KODI

    # Install GNOME Desktop and set it as the default desktop
    installGNOMEDesktop --y --setDefault

    # Check if all desktop environments were installed
    if [[ "$justInstalledKDEPLASMA" -eq 1 && "$justInstalledXFCE" -eq 1
        && "$justInstalledLXDE" -eq 1 && "$justInstalledLXQT" -eq 1
        && "$justInstalledCINNAMON" -eq 1 && "$justInstalledMATE" -eq 1
        && "$justInstalledBUDGIE" -eq 1 && "$justInstalledENLIGHTENMENT" -eq 1
        && "$justInstalledKODI" -eq 1 && "$justInstalledGNOME" -eq 1  ]]
    then # Just installed all desktop environment
        justInstalledAllEnvironments=1 # Set installed all to true using integer

        ${clear} # Clear terminal

        cPrint "YELLOW" "All $numberOfDesktopEnvironments desktop environments have been installed." |& tee -a $logFileName
        holdTerminal 4 # Hold for user to read
        break 2 # Break from nested loops

    else getAllInstalledDesktopEnvironments # Get all installed desktop environments

        if [[ "$foundKDEPLASMAInstalled" -eq 1 && "$foundXFCEInstalled" -eq 1
            && "$foundLXDEInstalled" -eq 1 && "$foundLXQTInstalled" -eq 1
            && "$foundCINNAMONInstalled" -eq 1 && "$foundMATEInstalled" -eq 1
            && "$foundBUDGIEInstalled" -eq 1
            && "$foundENLIGHTENMENTInstalled" -eq 1
            && "$foundKODIInstalled" -eq 1 && "$foundGNOMEInstalled" -eq 1 ]]
        then # All desktop environment already pre-installed
            ${clear} # Clear terminal
            cPrint "YELLOW" "All $numberOfDesktopEnvironments desktop environments have been installed." |& tee -a $logFileName
            holdTerminal 4 # Hold for user to read
        fi
    fi
}

# Function to install desktop environments
function displayInstallationOptions(){
    ${clear} # Clear terminal

    # Variable to indicate if a desktop environment is installed when
    # user is shown the installation menu
    local alreadyInstalled=""
    local alreadyInstalledLabel="(Already Installed!)"
    # Stores true or false in integer and ensures single instance running
    # of debug and update commands within the loop
    local -i ranDebugForInstalls=0

    # Get number of installed desktop environments
    getAllInstalledDesktopEnvironments

    local -l reEnteredChoice="false"
    while true; do # Start infinite loop
        ${clear} # Clear terminal

        if [ "$reEnteredChoice" == 'false' ]
        then

            cPrint "YELLOW" "Please select the desktop environment to install from the options below." |& tee -a $logFileName
            holdTerminal 2 # Hold for user to read
            if [ "$foundGNOMEInstalled" -eq 1 ]
            then # Indicate if desktop environment is already installed
              alreadyInstalled="$alreadyInstalledLabel"
            fi
            cPrint "NC" "
            \t\e[1;32m1. GNOME Desktop\e[0m: \e[1;33m$alreadyInstalled\e[0m
                        \n\t\tGNOME has satisfying graphical user interfaces and is prepared for massive deployments." |& tee -a $logFileName
            sleep .5s # Hold for user to read

            unset alreadyInstalled
            if [ "$foundKDEPLASMAInstalled" -eq 1 ]
            then # Indicate if desktop environment is already installed
                alreadyInstalled="$alreadyInstalledLabel"
            fi
            cPrint "NC" "
            \t\e[1;32m2. KDE PLASMA Desktop\e[0m: \e[1;33m$alreadyInstalled\e[0m
                        \n\t\tKDE has had a rapid evolution and is a perfectly mature desktop environment with a wide range of applications." |& tee -a $logFileName
            sleep .5s # Hold for user to read

            unset alreadyInstalled
            if [ "$foundXFCEInstalled" -eq 1 ]
            then # Indicate if desktop environment is already installed
                alreadyInstalled="$alreadyInstalledLabel"
            fi
            cPrint "NC" "
            \t\e[1;32m3. XFCE Desktop \e[0m: \e[1;33m$alreadyInstalled\e[0m
                        \n\t\tXFCE is a simple and lightweight graphical desktop, good for computers with limited resources." |& tee -a $logFileName
            sleep .5s # Hold for user to read

            unset alreadyInstalled
            if [ "$foundLXDEInstalled" -eq 1 ]
            then # Indicate if desktop environment is already installed
                alreadyInstalled="$alreadyInstalledLabel"
            fi
            cPrint "NC" "
            \t\e[1;32m4. LXDE Desktop \e[0m: \e[1;33m$alreadyInstalled\e[0m
                        \n\t\tLXDE aims to provide a fast, energy-efficient desktop environment with low memory usage." |& tee -a $logFileName
            sleep .5s # Hold for user to read

            unset alreadyInstalled
            if [ "$foundLXQTInstalled" -eq 1 ]
            then # Indicate if desktop environment is already installed
                alreadyInstalled="$alreadyInstalledLabel"
            fi
            cPrint "NC" "
            \t\e[1;32m5. LXQT Desktop \e[0m: \e[1;33m$alreadyInstalled\e[0m
                        \n\t\tLXQt is advanced, easy-to-use, and fast with an intuitive interface based on Qt technologies. It works fine with less powerful machines." |& tee -a $logFileName
            sleep .5s # Hold for user to read

            unset alreadyInstalled
            if [ "$foundCINNAMONInstalled" -eq 1 ]
            then # Indicate if desktop environment is already installed
                alreadyInstalled="$alreadyInstalledLabel"
            fi
            cPrint "NC" "
            \t\e[1;32m6. CINNAMON Desktop \e[0m: \e[1;33m$alreadyInstalled\e[0m
                        \n\t\tCinnamon is free and open-source, derives from GNOME 3 but follows traditional desktop metaphor conventions. (Common in Linux Mint distribution)." |& tee -a $logFileName
            sleep .5s # Hold for user to read

            unset alreadyInstalled
            if [ "$foundMATEInstalled" -eq 1 ]
            then # Indicate if desktop environment is already installed
                alreadyInstalled="$alreadyInstalledLabel"
            fi
            cPrint "NC" "
            \t\e[1;32m7. MATE Desktop \e[0m: \e[1;33m$alreadyInstalled\e[0m
                        \n\t\tMATE is the continuation of GNOME 2. It provides an intuitive and attractive desktop environment and offers a traditional desktop experience." |& tee -a $logFileName
            sleep .5s # Hold for user to read

            unset alreadyInstalled
            if [ "$foundBUDGIEInstalled" -eq 1 ]
            then # Indicate if desktop environment is already installed
                alreadyInstalled="$alreadyInstalledLabel"
            fi
            cPrint "NC" "
            \t\e[1;32m8. BUDGIE Desktop \e[0m: \e[1;33m$alreadyInstalled\e[0m
                        \n\t\tBudgie tightly integrates with the GNOME stack to offer an alternative desktop experience. It will install the minimal GNOME based package-set together with key budgie-desktop packages to work.(Popular in the Solus OS distribution)" |& tee -a $logFileName
            sleep .5s # Hold for user to read

            unset alreadyInstalled
            if [ "$foundENLIGHTENMENTInstalled" -eq 1 ]
            then # Indicate if desktop environment is already installed
                alreadyInstalled="$alreadyInstalledLabel"
            fi
            cPrint "NC" "
            \t\e[1;32m9. ENLIGHTENMENT Desktop \e[0m: \e[1;33m$alreadyInstalled\e[0m
                        \n\t\tEnlightenment has unique features including: a fully animated background, nice drop shadows around windows, backed by an extremely clean and optimized foundation of APIs." |& tee -a $logFileName
            sleep .5s # Hold for user to read

            unset alreadyInstalled
            if [ "$foundKODIInstalled" -eq 1 ]
            then # Indicate if desktop environment is already installed
                alreadyInstalleds="$alreadyInstalledLabel"
            fi
            cPrint "NC" "
            \t\e[1;32m10. KODI Desktop \e[0m: \e[1;33m$alreadyInstalled\e[0m
                        \n\t\tKodi is an opensource entertainment hub that brings all your digital media together into a beautiful, customisable and user friendly package." |& tee -a $logFileName
            sleep .5s # Hold for user to read

            unset alreadyInstalled # Unset installation check variable
            cPrint "NC" "
            \t\e[1;32m11. Install all of them \e[0m: This will set GNOME Desktop as your default desktop environment." |& tee -a $logFileName
            cPrint "NC" "
            \t\e[1;32m12 or 0. To Skip / Cancel \e[0m: This will skip desktop environment installation." |& tee -a $logFileName

            read -p ' option: ' choice
            choice=${choice,,} # Convert to lowercase
            # Display choice
            cPrint "GREEN" " You chose : $choice" |& tee -a $logFileName
        fi

        # Check if entered choice is a number
        if [[ $choice =~ $numberExpression ]]
        then # Choice is a number
            if (($choice >= 1 && $choice <= $numberOfDesktopEnvironments))
            then # Check if choice is within acceptable option parameters
                if [ "$ranDebugForInstalls" -eq 0 ]
                then # Prevent running of debug code repeatedly in the loop

                    ${clear} # Clear terminal

                    # Check for and install linnux headers
                    checkInstallLinuxHeaders

                    # Debug and configure packages, update system packages,
                    # upgrade software packages and update apt-file
                    checkDebugAndRollback --debug --update-upgrade

                    # Increment ranDebugForInstalls to 1 to set it to true
                    ranDebugForInstalls=$[ ranDebugForInstalls + 1 ]

                    ${clear} # Clear terminal
                fi
            fi
        fi

        # Check chosen option
        if  [[ "$choice" == '1' || "$choice" == 'gnome' ]]
        then # Option : GNOME Desktop
            # Check if desktop environment value was is empty. This is for
            # those who had installed a desktop environment. This ensures
            # that they are not forced to make GNOME Desktop as their default
            # if they were running any other desktop environment. This stage
            # will be skipped if another desktop environment was found during check.
            if [ -z "$currentDesktopEnvironment" ]
            then # (Variable empty) - Desktop environment not found
                # Install GNOME Desktop and set it as the default desktop
                installGNOMEDesktop --y --setDefault
            else
                installGNOMEDesktop # Install GNOME Desktop
            fi

            # Query if user wants to install another desktop environment
            # after installing the previous
            if queryInstallAnotherDesktopEnvironment
            then # Installation of another desktop environment - true
                sleep 1 # Hold loop
                continue # Resume iterations
            else # Installation of another desktop environment - false
                break # Break from loop
            fi

        elif  [[ "$choice" == '2' || "$choice" == 'kde'
              || "$choice" == 'kde plasma' || "$choice" == 'kdeplasma' ]]
        then # Option : KDE PLASMA Desktop

            # Install KDE PLASMA Desktop Desktop
            installKDEPlasmaDesktop

            # Query if user wants to install another desktop environment
            # after installing the previous
            if queryInstallAnotherDesktopEnvironment
            then # Installation of another desktop environment - true
                sleep 1 # Hold loop
                continue # Resume iterations
            else # Installation of another desktop environment - false
                break # Break from loop
            fi

        elif  [[ "$choice" == '3' || "$choice" == 'xfce' ]]
        then # Option : XFCE Desktop
            installXFCEDesktop # Install XFCE Desktop

            # Query if user wants to install another desktop environment
            # after installing the previous
            if queryInstallAnotherDesktopEnvironment
            then # Installation of another desktop environment - true
                sleep 1 # Hold loop
                continue # Resume iterations
            else # Installation of another desktop environment - false
                break # Break from loop
            fi

        elif  [[ "$choice" == '4' || "$choice" == 'lxde' ]]
        then # Option : LXDE Desktop
            installLXDEDesktop # Install LXDE Desktop

            # Query if user wants to install another desktop environment
            # after installing the previous
            if queryInstallAnotherDesktopEnvironment;
            then # Installation of another desktop environment - true
                sleep 1 # Hold loop
                continue # Resume iterations
            else # Installation of another desktop environment - false
                break # Break from loop
            fi

        elif  [[ "$choice" == '5' || "$choice" == 'lxqt' ]]
        then # Option : LXQT Desktop
            installLXQTDesktop # Install LXQT Desktop

            # Query if user wants to install another desktop environment
            # after installing the previous
            if queryInstallAnotherDesktopEnvironment
            then # Installation of another desktop environment - true
              sleep 1 # Hold loop
              continue # Resume iterations
            else # Installation of another desktop environment - false
              break # Break from loop
            fi

        elif  [[ "$choice" == '6' || "$choice" == 'cinnamon'
        || "$choice" == 'cinamon' ]]
        then # Option : CINNAMON
            installCinnamonDesktop # Install CINNAMON Desktop

            # Query if user wants to install another desktop environment
            # after installing the previous
            if queryInstallAnotherDesktopEnvironment
            then # Installation of another desktop environment - true
              sleep 1 # Hold loop
              continue # Resume iterations
            else # Installation of another desktop environment - false
              break # Break from loop
            fi

        elif  [[ "$choice" == '7' || "$choice" == 'mate' ]]
        then # Option : MATE Desktop
            installMateDesktop # Install MATE Desktop

            # Query if user wants to install another desktop environment
            after installing the previous
            if queryInstallAnotherDesktopEnvironment
            then # Installation of another desktop environment - true
                sleep 1 # Hold loop
                continue # Resume iterations
            else # Installation of another desktop environment - false
                break # Break from loop
            fi

        elif  [[ "$choice" == '8' || "$choice" == 'budgie' ]]
        then # Option : BUDGIE Desktop
            installBudgieDesktop # Install MATE Desktop

            # Query if user wants to install another desktop environment after
            # installing the previous
            if queryInstallAnotherDesktopEnvironment
            then # Installation of another desktop environment - true
                sleep 1 # Hold loop
                continue # Resume iterations
            else # Installation of another desktop environment - false
                break # Break from loop
            fi

        elif  [[ "$choice" == '9' || "$choice" == 'enlightenment' ]]
        then # Option : ENLIGHTENMENT Desktop
            installEnlightenmentDesktop # Install ENLIGHTENMENT Desktop

            # Query if user wants to install another desktop environment after
            # installing the previous
            if queryInstallAnotherDesktopEnvironment
            then # Installation of another desktop environment - true
                sleep 1 # Hold loop
                continue # Resume iterations
            else # Installation of another desktop environment - false
                break # Break from loop
            fi

        elif  [[ "$choice" == '10' || "$choice" == 'kodi' ]]
        then # Option : KODI Desktop
            installKodiDesktop # Install KODI Desktop

            # Query if user wants to install another desktop environment after
            # installing the previous
            if queryInstallAnotherDesktopEnvironment
            then # Installation of another desktop environment - true
                sleep 1 # Hold loop
                continue # Resume iterations
            else # Installation of another desktop environment - false
                break # Break from loop
            fi

        elif  [[ "$choice" == '11' || "$choice" == 'install all of them'
              || "$choice" == 'install all' || "$choice" == 'all' ]]
        then
            installAllDesktopEnvironments # Install all desktop environments
            break # Break from loop

        elif  [[ "$choice" == '12' || "$choice" == '0' || "$choice" == 'skip'
        || "$choice" == 'cancel' || "$choice" == 'exit' ]]
        then
            cPrint "RED" "Installation cancelled!\n" |& tee -a $logFileName
            holdTerminal 2 # Hold for user to read

            ${clear} # Clear terminal
            break # Break from loop

        else
          # Invalid entry
          cPrint "GREEN" "Invalid desktop selection!! Please try again." |& tee -a $logFileName

          # Re-enter choice
          read -p ' option: ' choice
          choice=${choice,,} # Convert to lowercases
          cPrint "GREEN" "You chose : $choice" # Display choice
          reEnteredChoice="true"
        fi
        sleep 1 # Hold loop
    done
}

: ' Function to initiate and setup newly installed desktop environments for
    users who did not have a desktop environment at the beginning'
function initSetupDesktopEnvironments(){

    if  checkForScriptAction "install-desktop" || checkForScriptAction "uninstall-desktop" || checkForScriptAction "install-xorg"
    then
        # Setting systemd to boot into graphical.target instead of multi-user.target
        cPrint "GREEN" "Setting systemd to boot to graphicat.target instead of multi-user.target." |& tee -a $logFileName
        holdTerminal 1 # Hold for user to read

        # Start / restart gdm3
        systemctl set-default graphical.target |& tee -a $logFileName
        sectionBreak
    fi

    # Restart desktop environments if no desktop environment had been installed
    # initially. Check if current desktop environment vaue was initially empty
    if [ -z "$currentDesktopEnvironment" ]
    then # Installed all and GNOME Desktop is the default
        if [ "$justInstalledAllEnvironments" -eq 1 ]
        then # GNOME is default
            cPrint "YELLOW" "Running --replace GNOME Desktop and disown to break HUP signal for all jobs if exists." |& tee -a $logFileName
            holdTerminal 2 # Hold for user to read

            # --replace and disown to break HUP signal for all jobs if exists
            gnome-shell --replace & disown &>> $logFileName
            cPrint "YELLOW" "Restarting gdm3 for GNOME Desktop." |& tee -a $logFileName
            holdTerminal 1 # Hold for user to read
            systemctl restart gdm3 |& tee -a $logFileName # Restart gdm3

        # Only if GNOME Installed
        elif [[ "$justInstalledKDEPLASMA" -eq 0 && "$justInstalledXFCE" -eq 0
            && "$justInstalledLXDE" -eq 0 && "$justInstalledLXQT" -eq 0
            && "$justInstalledCINNAMON" -eq 0 && "$justInstalledMATE" -eq 0
            && "$justInstalledBUDGIE" -eq 0 && "$justInstalledENLIGHTENMENT" -eq 0
            && "$justInstalledKODI" -eq 0 && "$justInstalledGNOME" -eq 1
            && "$justInstalledAllEnvironments" -eq 0 ]]
        then
            cPrint "YELLOW" "Running --replace GNOME Desktop and disown." |& tee -a $logFileName
            holdTerminal 1 # Hold for user to read

            # --replace and disown to break HUP signal for all jobs if exists
            gnome-shell --replace & disown &>> $logFileName

            cPrint "YELLOW" "Restarting gdm3 for GNOME Desktop." |& tee -a $logFileName
            holdTerminal 1 # Hold for user to read
            systemctl restart gdm3 |& tee -a $logFileName # Restart gdm3

        # Only if KDE PLASMA Desktop Installed
        elif [[ "$justInstalledKDEPLASMA" -eq 1 && "$justInstalledXFCE" -eq 0
            && "$justInstalledLXDE" -eq 0 && "$justInstalledLXQT" -eq 0
            && "$justInstalledCINNAMON" -eq 0 && "$justInstalledMATE" -eq 0
            && "$justInstalledBUDGIE" -eq 0 && "$justInstalledENLIGHTENMENT" -eq 0
            && "$justInstalledKODI" -eq 0 && "$justInstalledGNOME" -eq 0
            && "$justInstalledAllEnvironments" -eq 0 ]]
        then
            cPrint "YELLOW" "Enabling sddm for KDE PLASMA Desktop." |& tee -a $logFileName
            # Enable sddm.service for KDE PLASMA Desktop
            systemctl enable sddm.service |& tee -a $logFileName

            cPrint "YELLOW" "Reconfiguring sddm for KDE PLASMA Desktop." |& tee -a $logFileName
            dpkg-reconfigure sddm |& tee -a $logFileName

            cPrint "YELLOW" "Restarting sddm for KDE PLASMA Desktop." |& tee -a $logFileName
            systemctl restart sddm |& tee -a $logFileName
            holdTerminal 1 # Hold for user to read

        # Only if XFCE Desktop Installed
        elif [[ "$justInstalledKDEPLASMA" -eq 0 && "$justInstalledXFCE" -eq 1
            && "$justInstalledLXDE" -eq 0 && "$justInstalledLXQT" -eq 0
            && "$justInstalledCINNAMON" -eq 0 && "$justInstalledMATE" -eq 0
            && "$justInstalledBUDGIE" -eq 0 && "$justInstalledENLIGHTENMENT" -eq 0
            && "$justInstalledKODI" -eq 0 && "$justInstalledGNOME" -eq 0
            && "$justInstalledAllEnvironments" -eq 0 ]]
        then
            cPrint "YELLOW" "Restarting lightdm for XFCE Desktop." |& tee -a $logFileName
            holdTerminal 1 # Hold for user to read

            # Re-configure lightdm to load after boot
            cPrint "YELLOW" "Re-configuring lightdm for XFCE Desktop." |& tee -a $logFileName
            holdTerminal 1 # Hold for user to read
            dpkg-reconfigure lightdm |& tee -a $logFileName

            cPrint "YELLOW" "Creating a symlink to the unit file in /lib/systemd/system in /etc/systemd/system for lightdm to start at boot." |& tee -a $logFileName
            holdTerminal 1 # Hold for user to read

            `ll /etc/systemd/system/display-manager.service` |& tee -a $logFileName
            `ln -s /lib/systemd/system/lightdm.service /etc/systemd/system/display-manager.service` |& tee -a $logFileName
            cPrint "YELLOW" "Restarting lightdm and resetting it for XFCE Desktop." |& tee -a $logFileName
            holdTerminal 1 # Hold for user to read

            # Restart lightdm for XFCE Desktop and reset
            systemctl restart lightdm || xfwm4 --replace |& tee -a $logFileName

        # Only if ( LXDE or LXQT Desktops ) Installed
        elif [[ "$justInstalledLXDE" -eq 1 || "$justInstalledLXQT" -eq 1
            && "$justInstalledKDEPLASMA" -eq 0 && "$justInstalledXFCE" -eq 0
            && "$justInstalledCINNAMON" -eq 0 && "$justInstalledMATE" -eq 0
            && "$justInstalledBUDGIE" -eq 0 && "$justInstalledENLIGHTENMENT" -eq 0
            && "$justInstalledKODI" -eq 0 && "$justInstalledGNOME" -eq 0
            && "$justInstalledAllEnvironments" -eq 0 ]]
        then
            if [ "$justInstalledLXDE" -eq 1 ]
            then
                cPrint "YELLOW" "Restarting LXDE." |& tee -a $logFileName
                holdTerminal 1 # Hold for user to read

                # Start LXDE Desktop from terminal
                exec startlxde |& tee -a $logFileName

            elif [ "$justInstalledLXQT" -eq 1 ]
            then
                cPrint "YELLOW" "Restarting LXQT." |& tee -a $logFileName
                holdTerminal 1 # Hold for user to read

                # Start LXQT Desktop from terminal
                exec startlxqt |& tee -a $logFileName
            fi

        # Only if CINNAMON Desktop Installed
        elif [[ "$justInstalledKDEPLASMA" -eq 0 && "$justInstalledXFCE" -eq 0
            && "$justInstalledLXDE" -eq 0 && "$justInstalledLXQT" -eq 0
            && "$justInstalledCINNAMON" -eq 1 && "$justInstalledMATE" -eq 0
            && "$justInstalledBUDGIE" -eq 0 && "$justInstalledENLIGHTENMENT" -eq 0
            && "$justInstalledKODI" -eq 0 && "$justInstalledGNOME" -eq 0
            && "$justInstalledAllEnvironments" -eq 0 ]]
        then
            # Kill all instances of CINNAMON Desktop if exists
            killall cinnamon |& tee -a $logFileName

            # Re-configure CINNAMON Desktop
            cPrint "YELLOW" "Re-configuring CINNAMON Desktop." |& tee -a $logFileName
            holdTerminal 1 # Hold for user to read
            dpkg-reconfigure cinnamon |& tee -a $logFileName

            cPrint "YELLOW" "Running --replace for CINNAMON Desktop and disown to break HUP signal for all jobs if exists." |& tee -a $logFileName
            holdTerminal 1 # Hold for user to read

            # Replace CINNAMON Desktop and disown to break HUP signal for all
            # jobs if exists
            cinnamon --replace && disown &>> $logFileName
            cPrint "YELLOW" "Restarting mdm for CINNAMON Desktop." |& tee -a $logFileName
            holdTerminal 1 # Hold for user to read

            # Restart mdm for CINNAMON Desktop
            service restart mdm |& tee -a $logFileName

        # Only if MATE Desktop Installed
        elif [[ "$justInstalledKDEPLASMA" -eq 0 && "$justInstalledXFCE" -eq 0
            && "$justInstalledLXDE" -eq 0 && "$justInstalledLXQT" -eq 0
            && "$justInstalledCINNAMON" -eq 0 && "$justInstalledMATE" -eq 1
            && "$justInstalledBUDGIE" -eq 0 && "$justInstalledENLIGHTENMENT" -eq 0
            && "$justInstalledKODI" -eq 0 && "$justInstalledGNOME" -eq 0
            && "$justInstalledAllEnvironments" -eq 0 ]]
        then
            # Kill all instances of MATE-PANEL if exists
            killall mate-panel |& tee -a $logFileName

            # Re-configure CINNAMON Desktop
            cPrint "YELLOW" "Re-configuring MATE-PANEL." |& tee -a $logFileName
            holdTerminal 1 # Hold for user to read
            dpkg-reconfigure mate-panel |& tee -a $logFileName

            # Replace MATE-PANEL and disown to break HUP signal for all jobs if exists
            cPrint "YELLOW" "Running --replace for MATE-PANEL and disown to break HUP signal for all jobs if exists." |& tee -a $logFileName
            holdTerminal 1 # Hold for user to read
            mate-panel --replace && disown &>> $logFileName

        # Only if BUDGIE Installed
        elif [[ "$justInstalledKDEPLASMA" -eq 0 && "$justInstalledXFCE" -eq 0
            && "$justInstalledLXDE" -eq 0 && "$justInstalledLXQT" -eq 0
            && "$justInstalledCINNAMON" -eq 0 && "$justInstalledMATE" -eq 0
            && "$justInstalledBUDGIE" -eq 1 && "$justInstalledENLIGHTENMENT" -eq 0
            && "$justInstalledKODI" -eq 0 && "$justInstalledGNOME" -eq 0
            && "$justInstalledAllEnvironments" -eq 0 ]]
        then
            # Kill all instances of BUDGIE-PANEL if exists
            killall budgie-panel |& tee -a $logFileName

            # Re-configure BUDGIE Desktop
            cPrint "YELLOW" "Re-configuring BUDGIE-DESKTOP." |& tee -a $logFileName
            holdTerminal 1 # Hold for user to read
            dpkg-reconfigure budgie-desktop |& tee -a $logFileName

            # Replace BUDGIE-PANEL and disown to break HUP signal for all jobs
            # if exists
            cPrint "YELLOW" "Running --replace for BUDGIE-PANEL and disown to break HUP signal for all jobs if exists." |& tee -a $logFileName
            holdTerminal 1 # Hold for user to read
            budgie-panel --replace && disown &>> $logFileName

        # Only if ENLIGHTENMENT Desktop Installed
        elif [[ "$justInstalledKDEPLASMA" -eq 0 && "$justInstalledXFCE" -eq 0
            && "$justInstalledLXDE" -eq 0 && "$justInstalledLXQT" -eq 0
            && "$justInstalledCINNAMON" -eq 0 && "$justInstalledMATE" -eq 0
            && "$justInstalledBUDGIE" -eq 0 && "$justInstalledENLIGHTENMENT" -eq 1
            && "$justInstalledKODI" -eq 0 && "$justInstalledGNOME" -eq 0
            && "$justInstalledAllEnvironments" -eq 0 ]]
        then
            # Kill all instances of ENLIGHTENMENT Desktop if exists
            killall enlightenment & tee -a $logFileName

            # Re-configure ENLIGHTENMENT Desktop Desktop
            cPrint "YELLOW" "Re-configuring ENLIGHTENMENT Desktop." |& tee -a $logFileName
            holdTerminal 1 # Hold for user to read
            dpkg-reconfigure enlightenment |& tee -a $logFileName

            # Start ENLIGHTENMENT Desktop
            cPrint "YELLOW" "Starting ENLIGHTENMENT Desktop." |& tee -a $logFileName
            holdTerminal 1 # Hold for user to read
            enlightenment_start

        # Only if KODI Desktop Installed
        elif [[ "$justInstalledKDEPLASMA" -eq 0 && "$justInstalledXFCE" -eq 0
            && "$justInstalledLXDE" -eq 0 && "$justInstalledLXQT" -eq 0
            && "$justInstalledCINNAMON" -eq 0 && "$justInstalledMATE" -eq 0
            && "$justInstalledBUDGIE" -eq 0 && "$justInstalledENLIGHTENMENT" -eq 0
            && "$justInstalledKODI" -eq 1 && "$justInstalledGNOME" -eq 0
            && "$justInstalledAllEnvironments" -eq 0 ]]
        then
            # Kill all instances of KODI Desktop if exists
            killall kodi & tee -a $logFileName

            # Re-configure KODI Desktop Desktop
            cPrint "YELLOW" "Re-configuring KODI Desktop." |& tee -a $logFileName
            holdTerminal 1 # Hold for user to read
            dpkg-reconfigure kodi |& tee -a $logFileName

            cPrint "YELLOW" "Starting KODI Desktop." |& tee -a $logFileName
            holdTerminal 1 # Hold for user to read
            kodi # Start kodi Desktop
        fi
    fi
}

# Function to query user to confirm before uninstalling the default
# desktop environment
function queryUninstallDefaultDesktopEnvironment(){
    while true
    do # Start infinite loop

        ${clear} # Clear terminal

        # Prompt user to set GNOME Desktop as default
        cPrint "NC" "\e[1;32m$1\e[0m \e[1;33mis the current default desktop environment. Do you want to uninstall it?\n\t1. Y (Yes) - to uninstall $1.\n\t2. N (No) to cancel.\e[0m" |& tee -a $logFileName
        read -p ' option: ' contUninstChoice
        contUninstChoice=${contUninstChoice,,} # Convert to lowercase
        # Display choice
        cPrint "GREEN" " You chose : $contUninstChoice" |& tee -a $logFileName

        if  [[ "$contUninstChoice" == 'yes' || "$contUninstChoice" == 'y'
            || "$contUninstChoice" == '1' ]]
        then # Option : Yes
            return $(true) # Exit loop returning true
        elif [[ "$contUninstChoice" == 'no' || "$contUninstChoice" == 'n'
              || "$contUninstChoice" == '2' ]]
        then # Option : No
            return $(false) # Exit loop returning false
        else # Invalid entry
            cPrint "GREEN" "Invalid entry!! Please try again." |& tee -a $logFileName
        fi

        sleep 1 # Hold loop
    done
}

# Function to query user to purge desktop environment
function queryPurgeDesktopEnvironment(){
    while true
    do # Start infinite loop

        ${clear} # Clear terminal

        # Prompt user to set GNOME Desktop as default
        cPrint "NC" "Do you want to remove all \e[1;32m$1\'s\e[0m \e[1;33mfiles and settings too? \n\t1.Y (Yes) -to remove\e[0m \e[1;32m$1\'s\e[0m \e[1;33mfiles and settings.\n\t2. N (No) to skip deleting files.\e[0m" |& tee -a $logFileName
        read -p ' option: ' purgeChoice
        purgeChoice=${purgeChoice,,} # Convert to lowercase
        # Display choice
        cPrint "GREEN" " You chose : $purgeChoice" |& tee -a $logFileName

        if  [[ "$purgeChoice" == 'yes' || "$purgeChoice" == 'y'
        || "$purgeChoice" == '1' ]]
        then # Option : Yes
            return $(true) # Exit loop returning true
        elif [[ "$purgeChoice" == 'no' || "$purgeChoice" == 'n'
        || "$purgeChoice" == '2' ]]
        then # Option : No
            return $(false) # Exit loop returning false
        else # Invalid entry
            cPrint "GREEN" "Invalid entry!! Please try again." |& tee -a $logFileName
        fi

        sleep 1 # Hold loop
    done
}

# Function to clean up after uninstallation
function cleanUpAfterUninstallation(){
    cPrint "YELLOW" "\n\n Removing unused packages and cleaning up..." |& tee -a $logFileName
    holdTerminal 2 # Hold for user to read
    apt-get -f install |& tee -a $logFileName
    apt-get autoremove -y |& tee -a $logFileName
    apt-get clean |& tee -a $logFileName
    apt-get autoclean |& tee -a $logFileName
}

# Function to delete xSession of passed desktop environment
function deleteXSessions(){
    if [ ! -z $1 ]
    then # Check if parameter is null
        delete=rm -f $xSessionsPath/$1.desktop
        trap ${delete} # DElete and trap any errors
   fi
}

# Function to query if user wants to uninstall another desktop environment after
# uninstalling the previous
function queryUninstallAnotherDesktopEnvironment(){
    while true
    do # Start infinite loop
        ${clear} # Clear terminal

        # Prompt user to set GNOME Desktop as default
        cPrint "YELLOW" "Would you like to uninstall another desktop environment?\n\t1. Y (Yes) - to uninstall another.\n\t2. N (No) to cancel." |& tee -a $logFileName
        read -p ' option: ' queryUninstChoice
        queryUninstChoice=${queryUninstChoice,,} # Convert to lowercase
        # Display choice
        cPrint "GREEN" " You chose : $queryUninstChoice" |& tee -a $logFileName

        if  [[ "$queryUninstChoice" == 'yes' || "$queryUninstChoice" == 'y'
            || "$queryUninstChoice" == '1' ]]
        then # Option : Yes
            return $(true) # Exit loop returning true
        elif [[ "$queryUninstChoice" == 'no' || "$queryUninstChoice" == 'n'
              || "$queryUninstChoice" == '2' ]]
        then # Option : No
            return $(false) # Exit loop returning false
        else # Invalid entry
            cPrint "GREEN" "Invalid entry!! Please try again." |& tee -a $logFileName
        fi

        sleep 1 # Hold loop
    done
}

# Function to uninstall GNOME Desktop
function uninstallGnomeDesktop(){

    ${clear} # Clear terminal

    # Pass name of respective desktop environment as parameter
    if ! queryPurgeDesktopEnvironment "GNOME"
    then # Remove
        cPrint "YELLOW" "\n\n Uninstalling GNOME. This won\'t take long. Please wait..." |& tee -a $logFileName
        holdTerminal 4 # Hold for user to read

        apt-get remove gnome.desktop -y |& tee -a $logFileName
        apt-get remove gnome-classic.desktop -y |& tee -a $logFileName
        apt-get remove gnome-xorg.desktop -y |& tee -a $logFileName
        apt-get remove gnome-flashback-metacity.desktop -y |& tee -a $logFileName

    else # Purge
        cPrint "YELLOW" "\n\n Uninstalling GNOME and deleting its files and configuration. This won\'t take long. Please wait..." |& tee -a $logFileName
        holdTerminal 3 # Hold for user to read

        # Remove all files and packages includding XSessions
        apt-get purge --autoremove gnome.desktop -y |& tee -a $logFileName
        apt-get purge --autoremove gnome-classic.desktop -y |& tee -a $logFileName
        apt-get purge --autoremove gnome-xorg.desktop -y |& tee -a $logFileName
        apt-get purge --autoremove gnome-flashback-metacity.desktop -y |& tee -a $logFileName
        apt-get purge --autoremove gnome* -y |& tee -a $logFileName
    fi

    # Delete .desktop file from xSessions
    deleteXSessions "gnome*"

    # Add script actions to script actions array
    scriptActions=( "${scriptActions[@]}" "uninstall-desktop-gnome" )
    cleanUpAfterUninstallation # Clean up unused packages after uninstallation
    holdTerminal 1 # Hold

    # Get all installed desktop environments
    getAllInstalledDesktopEnvironments
    sectionBreak
}

# Function to uninstall KDE PLASMA Desktop
function uninstallKdeDesktop(){

    ${clear} # Clear terminal

    # Pass name of respective desktop environment as parameter
    if ! queryPurgeDesktopEnvironment "KDE PLASMA"
    then # Remove
        cPrint "YELLOW" "\n\n Uninstalling KDE PLASMA. This won\'t take long. Please wait..." |& tee -a $logFileName
        holdTerminal 2 # Hold for user to read

        apt-get remove kde-full kde-plasma-desktop -y |& tee -a $logFileName
        apt-get remove plasma.desktop -y |& tee -a $logFileName

    else # Purge
      cPrint "YELLOW" "\n\n Uninstalling KDE PLASMA and deleting its files and configuration. This won\'t take long. Please wait..." |& tee -a $logFileName
      holdTerminal 4 # Hold for user to read

      apt-get purge --autoremove kde-full -y |& tee -a $logFileName
      apt-get purge --autoremove kde-plasma-desktop -y |& tee -a $logFileName
      apt-get purge --autoremove plasma.desktop -y |& tee -a $logFileName
      apt-get purge --autoremove kde* -y |& tee -a $logFileName
    fi

    # Delete .desktop file from xSessions
    deleteXSessions "plasma*"

    # Add script actions to script actions array
    scriptActions=( "${scriptActions[@]}" "uninstall-desktop-kde" )
    cleanUpAfterUninstallation # Clean up unused packages after uninstallation
    holdTerminal 1 # Hold

    # Get all installed desktop environments
    getAllInstalledDesktopEnvironments
    sectionBreak
}

# Function to uninstall XFCE Desktop
function uninstallXfceDesktop(){

    ${clear} # Clear terminal

    # Pass name of respective desktop environment as parameter
    if ! queryPurgeDesktopEnvironment "XFCE"
    then # Remove
        cPrint "YELLOW" "\n\n Uninstalling XFCE. This won\'t take long. Please wait..." |& tee -a $logFileName
        holdTerminal 2 # Hold for user to read

        apt-get remove xfce.desktop xfce4 -y |& tee -a $logFileName
        apt-get remove task-xfce-desktop -y |& tee -a $logFileName
        apt-get remove xfconf xfce4-utils xfwm4 -y |& tee -a $logFileName
        apt-get remove xfce4-session xfdesktop4 -y |& tee -a $logFileName
        apt-get remove exo-utils xfce4-panel -y |& tee -a $logFileName
        apt-get remove xfce4-terminal thunar -y |& tee -a $logFileName

    else # Purge
        cPrint "YELLOW" "\n\n Uninstalling XFCE and deleting its files and configuration. This won\'t take long. Please wait..." |& tee -a $logFileName
        holdTerminal 4 # Hold for user to read

        apt-get purge --autoremove xfce4 -y |& tee -a $logFileName
        apt-get purge --autoremove xfce.desktop -y |& tee -a $logFileName
        apt-get purge --autoremove xfconf -y |& tee -a $logFileName
        apt-get purge --autoremove xfce4-utils -y |& tee -a $logFileName
        apt-get purge --autoremove xfwm4 -y |& tee -a $logFileName
        apt-get purge --autoremove xfce4-session -y |& tee -a $logFileName
        apt-get purge --autoremove xfdesktop4 -y |& tee -a $logFileName
        apt-get purge --autoremove exo-utils -y |& tee -a $logFileName
        apt-get purge --autoremove xfce4-panel -y |& tee -a $logFileName
        apt-get purge --autoremove xfce4-terminal -y |& tee -a $logFileName
        apt-get purge --autoremove thunar -y |& tee -a $logFileName
        apt-get purge --autoremove xfce* -y |& tee -a $logFileName
    fi

    # Delete .desktop file from xSessions
    deleteXSessions "xfce*"

    # Add script actions to script actions array
    scriptActions=( "${scriptActions[@]}" "uninstall-desktop-xfce" )
    cleanUpAfterUninstallation # Clean up unused packages after uninstallation
    holdTerminal 1 # Hold

    # Get all installed desktop environments
    getAllInstalledDesktopEnvironments
    sectionBreak
}

# Function to uninstall LXDE Desktop
function uninstallLxdeDesktop(){

    ${clear} # Clear terminal

    # Pass name of respective desktop environment as parameter
    if ! queryPurgeDesktopEnvironment "LXDE"
    then # Remove
        cPrint "YELLOW" "\n\n Uninstalling LXDE. This won\'t take long. Please wait..." |& tee -a $logFileName
        holdTerminal 2 # Hold for user to read

        apt-get remove lxde task-lxde-desktop -y |& tee -a $logFileName
        apt-get remove LXDE.desktop -y |& tee -a $logFileName
    else # Purge
        cPrint "YELLOW" "\n\n Uninstalling LXDE and deleting its files and configuration. This won\'t take long. Please wait..." |& tee -a $logFileName
        holdTerminal 4 # Hold for user to read

        apt-get purge --autoremove lxde |& tee -a $logFileName
        apt-get purge --autoremove task-lxde-desktop -y |& tee -a $logFileName
        apt-get purge --autoremove LXDE.desktop -y |& tee -a $logFileName
        apt-get purge --autoremove lxde* -y |& tee -a $logFileName
    fi

    # Delete .desktop file from xSessions
    deleteXSessions "LXDE*"

    # Add script actions to script actions array
    scriptActions=( "${scriptActions[@]}" "uninstall-desktop-lxde" )
    cleanUpAfterUninstallation # Clean up unused packages after uninstallation
    holdTerminal 1 # Hold

    # Get all installed desktop environments
    getAllInstalledDesktopEnvironments
    sectionBreak
}

# Function to uninstall LXQT Desktop
function uninstallLxqtDesktop(){

    ${clear} # Clear terminal

    # Pass name of respective desktop environment as parameter
    if ! queryPurgeDesktopEnvironment "LXQT"
    then # Remove
        cPrint "YELLOW" "\n\n Uninstalling LXQT. This won\'t take long. Please wait..." |& tee -a $logFileName
        holdTerminal 2 # Hold for user to read

        apt-get remove lxqt lxqt.desktop -y |& tee -a $logFileName
        apt-get remove task-lxqt.desktop -y |& tee -a $logFileName

    else # Purge
        cPrint "YELLOW" "\n\n Uninstalling LXQT and deleting its files and configuration. This won\'t take long. Please wait..." |& tee -a $logFileName
        holdTerminal 4 # Hold for user to read

        apt-get purge --autoremove lxqt lxqt.desktop -y |& tee -a $logFileName
        apt-get purge --autoremove task-lxqt.desktop -y |& tee -a $logFileName
        apt-get purge --autoremove lxqt* -y |& tee -a $logFileName
    fi

    # Delete .desktop file from xSessions
    deleteXSessions "lxqt*"

    # Add script actions to script actions array
    scriptActions=( "${scriptActions[@]}" "uninstall-desktop-lxqt" )
    cleanUpAfterUninstallation # Clean up unused packages after uninstallation
    holdTerminal 1 # Hold

    # Get all installed desktop environments
    getAllInstalledDesktopEnvironments
    sectionBreak
}

# Function to uninstall CINNAMON Desktop
function uninstallCinnamonDesktop(){

    ${clear} # Clear terminal

    # Pass name of respective desktop environment as parameter
    if ! queryPurgeDesktopEnvironment "CINNAMON"
    then # Remove
        cPrint "YELLOW" "\n\n Uninstalling CINNAMON. This won\'t take long. Please wait..." |& tee -a $logFileName
        holdTerminal 2 # Hold for user to read

        apt-get remove cinnamon-desktop-environment -y |& tee -a $logFileName
        apt-get remove task-cinnamon-desktop -y |& tee -a $logFileName
        apt-get remove cinnamon.desktop -y |& tee -a $logFileName

    else # Purge
        cPrint "YELLOW" "\n\n Uninstalling CINNAMON and deleting its files and configuration. This won\'t take long. Please wait..." |& tee -a $logFileName
        holdTerminal 4 # Hold for user to read

        apt-get purge --autoremove cinnamon-desktop-environment -y |& tee -a $logFileName
        apt-get purge --autoremove task-cinnamon-desktop -y |& tee -a $logFileName
        apt-get purge --autoremove cinnamon.desktop -y |& tee -a $logFileName
        apt-get purge --autoremove cinnamon* -y |& tee -a $logFileName
    fi

    # Delete .desktop file from xSessions
    deleteXSessions "cinnamon*"

    # Add script actions to script actions array
    scriptActions=( "${scriptActions[@]}" "uninstall-desktop-cinnamon" )
    cleanUpAfterUninstallation # Clean up unused packages after uninstallation
    holdTerminal 1 # Hold

    # Get all installed desktop environments
    getAllInstalledDesktopEnvironments
    sectionBreak
}

# Function to uninstall MATE Desktop
function uninstallMateDesktop(){

    ${clear} # Clear terminal

    # Pass name of respective desktop environment as parameter
    if ! queryPurgeDesktopEnvironment "MATE"
    then # Remove
        cPrint "YELLOW" "\n\n Uninstalling MATE. This won\'t take long. Please wait..." |& tee -a $logFileName
        holdTerminal 2 # Hold for user to read

        apt-get remove mate-desktop-environment -y |& tee -a $logFileName
        apt-get remove task-mate-desktop mate.desktop -y |& tee -a $logFileName

    else # Purge
        cPrint "YELLOW" "\n\n Uninstalling MATE and deleting its files and configuration. This won\'t take long. Please wait..." |& tee -a $logFileName
        holdTerminal 4 # Hold for user to read

        apt-get purge --autoremove mate-desktop-environment -y |& tee -a $logFileName
        apt-get purge --autoremove task-mate-desktop -y |& tee -a $logFileName
        apt-get purge --autoremove mate.desktop -y |& tee -a $logFileName
        apt-get purge --autoremove mate* -y |& tee -a $logFileName
    fi

    # Delete .desktop file from xSessions
    deleteXSessions "mate*"

    # Add script actions to script actions array
    scriptActions=( "${scriptActions[@]}" "uninstall-desktop-mate" )
    cleanUpAfterUninstallation # Clean up unused packages after uninstallation
    holdTerminal 1 # Hold

    # Get all installed desktop environments
    getAllInstalledDesktopEnvironments
    sectionBreak
}

# Function to uninstall BUDGIE Desktop
function uninstallBudgieDesktop(){

    ${clear} # Clear terminal

    # Pass name of respective desktop environment as parameter
    if ! queryPurgeDesktopEnvironment "BUDGIE"
    then # Remove
        cPrint "YELLOW" "\n\n Uninstalling BUDGIE. This won\'t take long. Please wait..." |& tee -a $logFileName
        holdTerminal 2 # Hold for user to read

        apt-get remove budgie-desktop -y |& tee -a $logFileName
        budgie.desktop -y |& tee -a $logFileName

    else # Purge
        cPrint "YELLOW" "\n\n Uninstalling BUDGIE and deleting its files and configuration. This won\'t take long. Please wait..." |& tee -a $logFileName
        holdTerminal 4 # Hold for user to read

        apt-get purge --autoremove budgie-desktop -y |& tee -a $logFileName
        apt-get purge --autoremove budgie.desktop -y |& tee -a $logFileName
        apt-get purge --autoremove budgie* -y |& tee -a $logFileName
    fi

    # Delete .desktop file from xSessions
    deleteXSessions "budgie*"

    # Add script actions to script actions array
    scriptActions=( "${scriptActions[@]}" "uninstall-desktop-budgie" )
    cleanUpAfterUninstallation # Clean up unused packages after uninstallation
    holdTerminal 1 # Hold

    # Get all installed desktop environments
    getAllInstalledDesktopEnvironments
    sectionBreak
}

# Function to uninstall ENLIGHTENMENT Desktop
function uninstallEnlightenmentDesktop(){

    ${clear} # Clear terminal

    # Pass name of respective desktop environment as parameter
    if ! queryPurgeDesktopEnvironment "ENLIGHTENMENT"
    then # Remove
        cPrint "YELLOW" "\n\n Uninstalling ENLIGHTENMENT. This won\'t take long. Please wait..." |& tee -a $logFileName
        holdTerminal 2 # Hold for user to read

        apt-get remove enlightenment -y |& tee -a $logFileName

    else # Purge
        cPrint "YELLOW" "\n\n Uninstalling ENLIGHTENMENT and deleting its files and configuration. This won\'t take long. Please wait..." |& tee -a $logFileName
        holdTerminal 4 # Hold for user to read

        apt-get purge --autoremove enlightenment -y |& tee -a $logFileName
        apt-get purge --autoremove enlightenment* -y |& tee -a $logFileName
    fi

    # Delete .desktop file from xSessions
    deleteXSessions "enlightenment*"

    # Add script actions to script actions array
    scriptActions=( "${scriptActions[@]}" "uninstall-desktop-enlightenment" )
    cleanUpAfterUninstallation # Clean up unused packages after uninstallation
    holdTerminal 1 # Hold

    # Get all installed desktop environments
    getAllInstalledDesktopEnvironments
    sectionBreak
}

# Function to uninstall KODI Desktop
function uninstallKodiDesktop(){

    ${clear} # Clear terminal

    # Pass name of respective desktop environment as parameter
    if ! queryPurgeDesktopEnvironment "KODI";\
    then # Remove
        cPrint "YELLOW" "\n\n Uninstalling KODI. This won\'t take long. Please wait..." |& tee -a $logFileName
        holdTerminal 2 # Hold for user to read

        apt-get remove kodi -y |& tee -a $logFileName

    else # Purge
        cPrint "YELLOW" "\n\n Uninstalling KODI and deleting its files and configuration. This won\'t take long. Please wait..." |& tee -a $logFileName
        holdTerminal 4 # Hold for user to read

        apt-get purge --autoremove kodi -y |& tee -a $logFileName
        apt-get purge --autoremove kodi* -y |& tee -a $logFileName
    fi

    # Delete .desktop file from xSessions
    deleteXSessions "kodi*"

    # Add script actions to script actions array
    scriptActions=( "${scriptActions[@]}" "uninstall-desktop-kodi" )
    cleanUpAfterUninstallation # Clean up unused packages after uninstallation
    holdTerminal 1 # Hold

    # Get all installed desktop environments
    getAllInstalledDesktopEnvironments
    sectionBreak
}

# Function to reconstruct uninstallation commands
function reconstructUninstallCommands(){

    declare -a uninstallCommands=( "uninstallGnomeDesktop" "uninstallKdeDesktop"
    "uninstallXfceDesktop" "uninstallLxdeDesktop" "uninstallLxqtDesktop"
    "uninstallCinnamonDesktop" "uninstallMateDesktop" "uninstallBudgieDesktop"
    "uninstallEnlightenmentDesktop" "uninstallKodiDesktop")

    # Convert elements of array to lower case
    declare -a uninstallCommandsLower=(${uninstallCommands[@],,})

    # Loop through uninstall command to get custom command for uninstalling
    # the current default desktop environment
    for selectedCommand in "${uninstallCommandsLower[@]}"
    do
        if [[ "$selectedCommand" == *"$1"* ]]
        then # Match selected command with current default desktop environment
            # Reconstruct command
            envName="$1"; envNameWordCase=""
            desktop="desktop"; desktopWordCase=""

            # Loop capitalizing respective word
            for word in $envName
            do
                envNameWordCase=${word^}
            done

            # Loop capitalizing respective word
            for word in $desktop
            do
                desktopWordCase=${word^}
            done

            # Updating selected command
            selectedCommand=${selectedCommand/$envName/$envNameWordCase}

            # Updating selected command
            selectedCommand=${selectedCommand/$desktop/$desktopWordCase}

            # Setting reconstructed command
            reconstructedCommand="$selectedCommand"
        fi
    done
}

# Function to create uninstallation order
function createUninstallationOrder(){

    currentDefault="" # Stores the current default desktop environment

    # Get current default desktop
    if [ "$XDG_CURRENT_DESKTOP" = "" ]
    then # Check for current desktop environment
        # Check for installed  Desktop environments
        currentDefault=$(echo "$XDG_DATA_DIRS" | sed 's/.*\(gnome\|kde\|xfce\|lxde\|lxqt\|cinnamon\|mate\|budgie\|enlightenment\|kodi\).*/\1/')
    else currentDefault=$XDG_CURRENT_DESKTOP # Get XDG current desktop
    fi
    currentDefault=${currentDefault,,} # Convert to lowercase

    # Declare an array of desktop environments to be uninstalled
    declare -a uninstArray=($uninstallationList)

    for environment in "${uninstArray[@]}"
    do
        if [ "$currentDefault" != "$environment" ]
        then # Check if the current item is the default desktop environment
            if [[ "$environment" == 'gnome' ]]
            then
                uninstallOrder=( "${uninstallOrder[@]}" "uninstallGnomeDesktop" )
            elif [[ "$environment" == 'kde' ]]
            then
                uninstallOrder=( "${uninstallOrder[@]}" "uninstallKdeDesktop" )
            elif [[ "$environment" == 'xfce' ]]
            then
                uninstallOrder=( "${uninstallOrder[@]}" "uninstallXfceDesktop" )
            elif [[ "$environment" == 'lxde' ]]
            then
                uninstallOrder=( "${uninstallOrder[@]}" "uninstallLxdeDesktop" )
            elif [[ "$environment" == 'lxqt' ]]
            then
                uninstallOrder=( "${uninstallOrder[@]}" "uninstallLxqtDesktop" )
            elif [[ "$environment" == 'cinnamon' ]]
            then
                uninstallOrder=( "${uninstallOrder[@]}" "uninstallCinnamonDesktop" )
            elif [[ "$environment" == 'mate' ]]
            then
                uninstallOrder=( "${uninstallOrder[@]}" "uninstallMateDesktop" )
            elif [[ "$environment" == 'budgie' ]]
            then
                uninstallOrder=( "${uninstallOrder[@]}" "uninstallBudgieDesktop" )
            elif [[ "$environment" == 'enlightenment' ]]
            then
                uninstallOrder=( "${uninstallOrder[@]}" "uninstallEnlightenmentDesktop" )
            elif [[ "$environment" == 'kodi' ]]
            then
                uninstallOrder=( "${uninstallOrder[@]}" "uninstallKodiDesktop" )
            fi
        else
            # Reconstruct command for default desktop environment
            reconstructUninstallCommands "$currentDefault"
        fi
    done

    # Check if reconstructed command is empty
    if [ ! -z "$reconstructedCommand" ]
    then # Not empty
        # Add uninstall default desktop command at the end of order array
        uninstallOrder=( "${uninstallOrder[@]}" "$reconstructedCommand" )
    else
        cPrint "RED" "$currentDefault will not be uninstalled since it is not supported in the current version $scriptVersion"
    fi
}

# Function to uninstall all desktop environments
function uninstallAllDesktopEnvironments(){

    createUninstallationOrder # Generate desktop environment uninstallation order
    cPrint "GREEN" "Uninstalling all desktop environment. PLease wait!!" |& tee -a $logFileName

    secondLastCommand=$[ noOfInstalledDesktopEnvironments - 1 ]
    count=0
    for uninstallCommand in "${uninstallOrder[@]}"
    do
        count=$[ count + 1 ]
        if [ $count -gt $secondLastCommand ]
        then
            # Check if environment to be uninstalled is the current default
            # and ask user to confirm
            # Exctracting desktop environment name from command for user query
            name=${uninstallCommand/"uninstall"/""}

            # Exctracting desktop environment name from command for user query
            name=${name/"Desktop"/""}

            # Pass name of respective desktop environment as parameter
            if ! queryUninstallDefaultDesktopEnvironment "$name"
            then
                continue # Cancel uninstallation and resume iterations
            fi
            ${uninstallCommand};
        else ${uninstallCommand}
        fi
    done

    getAllInstalledDesktopEnvironments --displayList
    if [ "$noOfInstalledDesktopEnvironments" -eq 0 ]
    then
        cPrint "YELLOW" "Finished uninstalling all desktop environments." |& tee -a $logFileName
        holdTerminal 2 # Hold for user to read
    fi
}

# Function to select and uninstall a desktop environment
function displayUninstallationOptions(){

    ${clear} # Clear terminal

    # Stores true or false in integer and ensures single instance running of
    # debug and update commands within the loop
    local -i ranDebugForUninstalls=0

    # Get number of installed desktop environments
    getAllInstalledDesktopEnvironments

    while true
    do # Start infinite loop
        ${clear} # Clear terminal

        if [ "$noOfInstalledDesktopEnvironments" -gt 0 ]
        then # 1 or more desktop environment installed
            # Get all installed desktop environments and display them
            getAllInstalledDesktopEnvironments --displayList

            cPrint "YELLOW" "Please select a desktop environment to uninstall from the list above!" |& tee -a $logFileName
            read -p ' option: ' choice
            choice=${choice,,} # Convert to lowercase
            # Display choice
            cPrint "GREEN" " You chose : $choice" |& tee -a $logFileName

            # Check if entered choice is a number
            if [[ $choice =~ $numberExpression ]]
            then # Choice is a number

                unset list # Unset List
                # Get list of all installed desktop environments
                list="$listOfInstalledDesktopEnvironments"
                unset filterParam # Unset filter parameter
                # Get text between list number and 'Desktop' word
                filterParam="$choice. \K.*?(?= Desktop.)"
                unset option # Unset option
                # Grep string to get option
                option=$(grep -oP "$filterParam" <<< "$list")

                # Check if option is empty or not
                if [ ! -z "$option" ]
                then # Option is not empty
                    option=${option,,} # Convert to lowercase
                    unset choice # Unset choice
                    choice="$option" # Set option to choice

                else # Get option to uninstall all desktop environments
                    unset filterParam2 # Unset filter parameter
                    # Get text between list number and 'desktop environments' words
                    filterParam2="$choice. \K.*?(?= desktop environments.)"
                    unset option # Unset option
                    # Grep string to get option
                    option=$(grep -oP "$filterParam2" <<< "$list")

                    # Check if option is empty or not
                    if [ ! -z "$option" ]
                    then # Option is not empty
                        option=${option,,} # Convert to lowercase
                        unset choice # Unset choice
                        choice="$option" # Set option to choice

                    else # Get cancel option
                        unset filterParam3 # Unset filter parameter
                        # Get text between list number and period
                        filterParam3="$choice. \K.*?(?= .)"
                        unset option # Unset option
                        # Grep string to get option
                        option=$(grep -oP "$filterParam3" <<< "$list")
                        option=${option//.} # Strip period from option
                        option=${option,,} # Convert to lowercase
                        unset choice # Unset choice
                        choice="$option" # Set option to choice
                    fi
                fi
            fi

            if [ "$ranDebugForUninstalls" -eq 0 ]
            then # Prevent running of debug code repeatedly in the loop
                ${clear} # Clear terminal

                # Check if uninstallation was cancelled
                if [[ "$choice" != 'cancel' ]]
                then
                    # Debug and configure packages, update system packages,
                    # upgrade software packages and update apt-file
                    checkDebugAndRollback --debug --update-upgrade
                fi

                # Increment ranDebugForUninstalls to 1 to set it to true
                ranDebugForUninstalls=$[ ranDebugForUninstalls + 1 ]
                ${clear} # Clear terminal
            fi

            currentDefault="" # Stores the current default desktop environment
            # Get current default desktop
            if [ "$XDG_CURRENT_DESKTOP" = "" ]
            then # Check for current desktop environment
                # Check for installed  Desktop environments
                currentDefault=$(echo "$XDG_DATA_DIRS" | sed 's/.*\(gnome\|kde\|xfce\|lxde\|lxqt\|cinnamon\|mate\|budgie\|enlightenment\|kodi\).*/\1/')
            else currentDefault=$XDG_CURRENT_DESKTOP # Get XDG current desktop
            fi
            currentDefault=${currentDefault,,} # Convert to lowercase

            # Check if environment to be uninstalled is the current
            # default and ask user to confirm
            if [[ "$choice" == "$currentDefault" ]]
            then
                # Pass name of respective desktop environment as parameter
                if ! queryUninstallDefaultDesktopEnvironment "$choice"
                then continue # Cancel uninstallation and resume iterations
                fi
            fi

            # Check chosen option and uninstall the respective desktop environment
            if  [[ "$choice" == 'gnome' || "$choice" == 'gnome desktop' ]]
            then # Option : GNOME Desktop
                uninstallGnomeDesktop; choice="" # Uninstall GNOME Desktop

                # Query if user wants to uninstall another desktop environment
                # after uninstalling the previous
                if queryUninstallAnotherDesktopEnvironment
                then # Installation of another desktop environment - true
                    sleep 1 # Hold loop
                    continue # Resume iterations
                else # Installation of another desktop environment - false
                    break # Break from loop
                fi

            elif  [[ "$choice" == 'kde' || "$choice" == 'kde plasma desktop'
            || "$choice" == 'kde plasma' || "$choice" == 'kde desktop' ]]
            then # Option : KDE PLASMA Desktop
                uninstallKdeDesktop # Uninstall KDE PLASMA Desktop Desktop

                # Query if user wants to uninstall another desktop environment
                # after uninstalling the previous
                if queryUninstallAnotherDesktopEnvironment
                then # Installation of another desktop environment - true
                    sleep 1 # Hold loop
                    continue # Resume iterations
                else # Installation of another desktop environment - false
                    break # Break from loop
                fi

            elif  [[ "$choice" == 'xfce' || "$choice" == 'xfce desktop' ]]
            then # Option : XFCE Desktop
                uninstallXfceDesktop # Uninstall XFCE Desktop

                # Query if user wants to uninstall another desktop environment
                # after uninstalling the previous
                if queryUninstallAnotherDesktopEnvironment
                then # Installation of another desktop environment - true
                    sleep 1 # Hold loop
                    continue # Resume iterations
                else # Installation of another desktop environment - false
                    break # Break from loop
                fi

            elif  [[ "$choice" == 'lxde' || "$choice" == 'lxde desktop' ]]
            then # Option : LXDE Desktop
                uninstallLxdeDesktop # Uninstall LXDE Desktop

                # Query if user wants to uninstall another desktop environment
                # after uninstalling the previous
                if queryUninstallAnotherDesktopEnvironment
                then # Installation of another desktop environment - true
                    sleep 1 # Hold loop
                    continue # Resume iterations
                else # Installation of another desktop environment - false
                    break # Break from loop
                fi

            elif  [[ "$choice" == 'lxqt' || "$choice" == 'lxqt desktop' ]]
            then # Option : LXQT Desktop
              uninstallLxqtDesktop # Uninstall LXQT Desktop

                # Query if user wants to uninstall another desktop environment
                # after uninstalling the previous
                if queryUninstallAnotherDesktopEnvironment
                then # Installation of another desktop environment - true
                  sleep 1 # Hold loop
                  continue # Resume iterations
                else # Installation of another desktop environment - false
                  break # Break from loop
                fi

            elif  [[ "$choice" == 'cinnamon'
            || "$choice" == 'cinnamon desktop' ]]
            then # Option : CINNAMON
                uninstallCinnamonDesktop # Uninstall CINNAMON Desktop

                # Query if user wants to uninstall another desktop environment
                # after uninstalling the previous
                if queryUninstallAnotherDesktopEnvironment
                then # Installation of another desktop environment - true
                  sleep 1 # Hold loop
                  continue # Resume iterations
                else # Installation of another desktop environment - false
                  break # Break from loop
                fi

            elif  [[ "$choice" == 'mate' || "$choice" == 'mate desktop' ]]
            then # Option : MATE Desktop
                uninstallMateDesktop # Uninstall MATE Desktop

                # Query if user wants to uninstall another desktop environment
                # after uninstalling the previous
                if queryUninstallAnotherDesktopEnvironment
                then # Installation of another desktop environment - true
                    sleep 1 # Hold loop
                    continue # Resume iterations
                else # Installation of another desktop environment - false
                    break # Break from loop
                fi

            elif  [[ "$choice" == 'budgie' || "$choice" == 'budgie desktop' ]]
            then # Option : BUDGIE Desktop
                uninstallBudgieDesktop # Uninstall MATE Desktop

                # Query if user wants to uninstall another desktop environment
                # after uninstalling the previous
                if queryUninstallAnotherDesktopEnvironment
                then # Installation of another desktop environment - true
                    sleep 1 # Hold loop
                    continue # Resume iterations
                else # Installation of another desktop environment - false
                    break # Break from loop
                fi

            elif  [[ "$choice" == 'enlightenment'
            || "$choice" == 'enlightenment desktop' ]]
            then # Option : ENLIGHTENMENT Desktop
                uninstallEnlightenmentDesktop # Uninstall ENLIGHTENMENT Desktop

                # Query if user wants to uninstall another desktop environment
                # after uninstalling the previous
                if queryUninstallAnotherDesktopEnvironment
                then # Installation of another desktop environment - true
                    sleep 1 # Hold loop
                    continue # Resume iterations
                else # Installation of another desktop environment - false
                    break # Break from loop
                fi

            elif  [[ "$choice" == 'kodi' || "$choice" == 'kodi desktop' ]]
            then # Option : KODI Desktop
                uninstallKodiDesktop # Uninstall KODI Desktop

                # Query if user wants to uninstall another desktop environment
                # after uninstalling the previous
                if queryUninstallAnotherDesktopEnvironment
                then # Installation of another desktop environment - true
                    sleep 1 # Hold loop
                    continue # Resume iterations
                else # Installation of another desktop environment - false
                    break # Break from loop
                fi

            elif  [[ "$choice" == 'uninstall all'
            || "$choice" == 'uninstall all desktop environments' ]]
            then
                # Uninstall all desktop environments
                uninstallAllDesktopEnvironments
                break # Uninstall all desktop environments

            elif  [[ "$choice" == 'cancel' ]]
            then
                cPrint "RED" "\n\n Uninstallation cancelled!\n" |& tee -a $logFileName
                holdTerminal 1 # Hold for user to read

                ${clear} # Clear terminal
                break # Break from loop - Uninstallation cancelled

            else
                cPrint "GREEN" "Invalid desktop selection!! Please try again." |& tee -a $logFileName # Invalid entry
            fi

            sleep 1 # Hold loop
        else
            cPrint "RED" "\n\n You have not installed any desktop environment.\n"
            holdTerminal 2 # Hold for user to read
            break
        fi
    done
}

# Function to display the main script menu
function displayMainMenu(){
    ${clear} # Clear terminal

    while true
    do # Start infinite loop
        ${clear} # Clear terminal

        # Prompt user to set GNOME Desktop as default
        echo ""; cPrint "YELLOW" "Please select an action below:\n\t1. Install a desktop environment.\n\t2. Uninstall/remove a desktop environment.\n\t3. Cancel/Exit" |& tee -a $logFileName
        read -p ' option: ' mainMenuChoice
        mainMenuChoice=${mainMenuChoice,,} # Convert to lowercase
        # Display choice
        cPrint "GREEN" " You chose : $mainMenuChoice" |& tee -a $logFileName

        if  [[ "$mainMenuChoice" == '1' || "$mainMenuChoice" == 'install' ]]
        then # Option : Yes
            # Checking for internet connection before continuing
            if ! isConnected
            then
                exitScript --connectionFailure # Exit script on connection failure
            fi

            displayInstallationOptions # Install a desktop environment

        elif [[ "$mainMenuChoice" == '2' || "$mainMenuChoice" == 'uninstall'
              || "$mainMenuChoice" == 'remove' ]]
        then # Option : No
            # Checking for internet connection before continuing
            if ! isConnected
            then # Exit script on connection failure
                exitScript --connectionFailure
            fi

            displayUninstallationOptions # Uninstall a desktop environment

        elif [[ "$mainMenuChoice" == '3' || "$mainMenuChoice" == 'cancel'
              || "$mainMenuChoice" == 'exit' ]]
        then # Option : No
            ${clear} # Clear terminal
            # Increment setupCancelled value
            setupCancelled=$[ setupCancelled + 1 ]
            cPrint "RED" "\n\n Script cancelled!!\n" |& tee -a $logFileName
            break # Break from loop

        else # Invalid entry
            cPrint "GREEN" "Invalid entry!! Please try again." |& tee -a $logFileName
        fi

        sleep 1 # Hold loop
    done
}


: 'Beginning of scripts execution'
${clear} # Clear terminal

startTime=`date +%s` # Get start time
initScript # Initiate script to get required packages

# Check for desktop environment
checkForDefaultDesktopEnvironment --noResponse

# Display main menu
displayMainMenu

if  checkForScriptAction "install-desktop" || checkForScriptAction "install-xorg"
then
    : ' Initiate and setup newly installed desktop environments for users
        who did not have a desktop environment at the beginning'
    initSetupDesktopEnvironments
fi

# Exit script
exitScript --end
