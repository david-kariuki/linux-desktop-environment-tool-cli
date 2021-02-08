# Copyright (c) 2020 by David Kariuki (dk). All Rights Reserved.

#!/bin/bash

declare -r targetLinux="Debian Linux"
declare -r scriptVersion="1.0" # Stores scripts version
declare -l -r scriptName="dk-debug-cli" # Set to lowers and read-only
declare -l -r networkTestUrl="www.google.com" # Stores the networkTestUrl (Set to lowers and read-only)
declare -l startTime="" # Start time of execution
declare -l totalExecutionTime="" # Total execution time in days:hours:minutes:seconds

clear=clear # Command to clear terminal

: ' cPrint - Custom function to create a custom coloured print
    |& tee -a $logFileName - append output stream to logs and terminal'
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

    ${clear} # Clear terminal
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

# Function to check for and install linux headers
function checkInstallLinuxHeaders(){

    ${clear} # Clear terminal

    # Path to linux headers
    headersPath=/usr/src/linux-headers-$(uname -r)

    # Check for linux headers installation
    if check=$(ls -l $headersPath &> /dev/null)
    then # Linux headers installed

        # Prevent message showing many times during loop
        if [ "$checkedForLinuxHeaders" -eq 0 ]
        then
            cPrint "NC" "\e[1;33mChecked for linux headers.\e[0m \e[1;32mLinux headers installed.\e[0m\n"
            holdTerminal 1 # Hold
            checkedForLinuxHeaders=1
            linuxHeadersInstalled=1
        fi
    else # Linux headers not installed

        # Install linux headers
        cPrint "YELLOW" "Installing linux headers.\n"
        apt-get install linux-headers-$(uname -r) |& tee -a $logFileName

        runDebug
    fi
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


    ${clear} # Clear terminal

    # Creating integer variable
    local -i count=0 # Declare loop count variable
    local -i -r retrNum=4 # Declare and set number of retries to read-only
    local -i -r maxRetr=$[retrNum + 1] # Declare and set max retry to read-only
    local -i -r countDownTime=30 # Declare and set retry to read-only

    while :
    do # Starting infinite loop
        cPrint "YELLOW" "\nChecking for internet connection!!" |& tee -a $logFileName
        if `nc -zw1 $networkTestUrl 443` && echo |openssl s_client -connect $networkTestUrl:443 2>&1 |awk '
            handshake && $1 == "Verification" { if ($2=="OK") exit; exit 1 }
	          $1 $2 == "SSLhandshake" { handshake = 1 }' &> /dev/null
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

# Function to update system packages, upgrade software packages
# and update apt-file
function updateAndUpgrade(){

    ${clear} # Clear terminal

    # Checking for connection after every major sep incase of network
    # failure during one stage
    if isConnected
    then # Checking for internet connection
        # Internet connection established
        cPrint "YELLOW" "Updating system packages." |& tee -a $logFileName
        holdTerminal 1 # Hold for user to read
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
        holdTerminal 1 # Hold for user to read
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
        holdTerminal 1 # Hold for user to read
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
        holdTerminal 1 # Hold for user to read
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
        holdTerminal 1 # Hold for user to read
        apt-get install apt-file -y |& tee -a $logFileName
        holdTerminal 1 # Hold for user to read
        sectionBreak

        cPrint "YELLOW" "Running apt-file update." |& tee -a $logFileName
        holdTerminal 1
        apt-file update |& tee -a $logFileName
        holdTerminal 1 # Hold for user to read

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
function runDebug(){

    ${clear} # Clear terminal

    if [ "$1" == '--debug' ]
    then # Check for debug switch
        cPrint "GREEN" "Checking for errors and debugging. Please wait..." |& tee -a $logFileName
    elif [ "$1" == '--network' ]
    then # Check for network switch
        cPrint "GREEN" "Debugging.... Please wait..." |& tee -a $logFileName
    fi
    holdTerminal 1 # Hold for user to read

    cPrint "YELLOW"  "Checking for broken/unmet dependencies and fixing broken installs." |& tee -a $logFileName
    holdTerminal 1 # Hold for user to read
    apt-get check |& tee -a $logFileName
    apt-get --fix-broken install |& tee -a $logFileName
    sectionBreak

    cPrint "YELLOW" "Cleaning apt-get cache, disk space and removing unused packages." |& tee -a $logFileName
    holdTerminal 1 # Hold for user to read
    apt-get autoclean -y |& tee -a $logFileName
    apt-get clean -y |& tee -a $logFileName
    apt-get autoremove -y |& tee -a $logFileName
    sectionBreak

    cPrint "YELLOW" "Configuring packages." |& tee -a $logFileName
    holdTerminal 1 # Hold for user to read
    dpkg --configure -a |& tee -a $logFileName
    cPrint "NC" "dpkg package configuration completed." |& tee -a $logFileName
    holdTerminal 1 # Hold for user to read
    sectionBreak

    if [[ "$2" == '--update-upgrade' && "$1" == '--debug' ]]
    then # Check for update-upgrade switch
        # Update system packages and upgrade software packages
        updateAndUpgrade
    fi

    cPrint "YELLOW" "Cleaning apt-get cache, disk space and removing unused packages." |& tee -a $logFileName
    holdTerminal 1 # Hold for user to read
    apt-get autoclean -y |& tee -a $logFileName
    apt-get clean -y |& tee -a $logFileName
    apt-get --fix-broken install |& tee -a $logFileName
    apt-get autoremove -y |& tee -a $logFileName
    sectionBreak

    cPrint "YELLOW" "Updating AppStream cache." |& tee -a $logFileName
    holdTerminal 1 # Hold for user to read
    appstreamcli refresh --force |& tee -a $logFileName
    sectionBreak

    cPrint "GREEN" "Checking and debugging completed successfuly!!" |& tee -a $logFileName
    sectionBreak
}

# Function to query if user wants to install another desktop environment
# after installing the previous
function displayMainMenu(){

    ${clear} # Clear terminal

    while true
    do # Start infinite loop
        ${clear} # Clear terminal

        # Prompt user to set GNOME Desktop as default
        cPrint "YELLOW" "Select operation below to proceed?\n\t1. Debug.\n\t2. Update and Upgrade.\n\t3. Exit." |& tee -a $logFileName
        read -p ' option: ' queryChoice
        queryChoice=${queryChoice,,} # Convert to lowercase
        # Display choice
        cPrint "GREEN" " You chose : $queryChoice" |& tee -a $logFileName

        if  [[ "$queryChoice" == '1' || "$queryChoice" == 'debug' ]]
        then # Option : Yes

            ${clear} # Clear terminal
            runDebug # Run debug

        elif [[ "$queryChoice" == '2' || "$queryChoice" == 'upgrade'
        || "$queryChoice" == 'upgradeUpgrade' || "$queryChoice" == 'upgradeAndUpgrade' ]]
        then # Option : No

            ${clear} # Clear terminal
            updateAndUpgrade # Run updates and upgrades

        elif [[ "$queryChoice" == '3' || "$queryChoice" == 'exit' ]]
        then

            ${clear} # Clear terminal
            exitScript --end # Exit script

        else
            # Invalid entry
            cPrint "GREEN" "Invalid entry!! Please try again." |& tee -a $logFileName
        fi

        sleep 1 # Hold loop
    done
}

# Functio to start script
function initScript(){

    startTime=`date +%s` # Get start time

    ${clear} # Clear terminal
    echo ""

    cPrint "GREEN" "Fetching required packages."
    apt-get install netcat &> /dev/null # Install netcat if not installed to be used for connection check

    holdTerminal 1 # Hold
    ${clear} # Clear terminal

    echo ""; cPrint "RED" "Running as $USER!!"
    cPrint "YELLOW"	"This script will perform basic debug operations, updates and upgrades on your $targetLinux."
    holdTerminal 5 # Hold for user to read

    # Check if user is running as root
    if checkIfUserIsRoot
    then
        if isConnected
        then # Network connection established

            displayMainMenu # Display main menu with options

        else
            exitScript --connectionFailure # Exit script on connection failure
        fi
    fi
}

# Function to exit script with custom coloured message
function exitScript(){

    cPrint "RED" "Exiting script..." # Display exit message
    holdTerminal 1 # Hold for user to read

    if [ "$1" == '--end' ]
    then # Check for --end switch
        ${clear} # Clear terminal

        cd ~ || exit # Change to home directory
        displayScriptInfo # Display script information

        # Get script execution time
        endTime=`date +%s` # Get start time
        executionTimeInSeconds=$((endTime-startTime))
        formatTime $executionTimeInSeconds # Calculate time in days:hours:minutes:seconds

        # Draw logo
        printf "\n\n       __   __\n      |  | |  |  ___\n      |  | |  | /  /\n    __|  | |  |/  /\n  /  _   | |     <\n |  (_|  | |  |\  \ \n  \______| |__| \__\ \n\n "
        cPrint "YELLOW" "Script execution time : $totalExecutionTime \n"
        cPrint "RED" "Exited script...\n\n" # Display exit message


    elif [ "$1" == '--connectionFailure' ]
    then
        cPrint "RED" "\n\n This script requires a stable internet connection to work fully!!"
        cPrint "NC" "Please check your connection settings and re-run the script.\n"
    fi

    exit 0 # Exit script
}

# Check for passed arguments
if [ "$1" == '--debug' ]
then

    runDebug # Run debugs

elif [ "$1" == '--upgrade' ]
then

    updateAndUpgrade # Run update and upgrade

else
    # No parameter passed

    initScript # Initiate script
    exitScript --end # Exit script
fi
