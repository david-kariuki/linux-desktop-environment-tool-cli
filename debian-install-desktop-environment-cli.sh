#!/bin/bash

# Common code & words docs
# dksay - Custom function to create a custom coloured print
# |& tee -a $logFileName - append output stream to logs and output to terminal

declare -l currentDesktopEnvironment="" # Stores the value of the current installed desktop environment
declare -l installedGNOME=0 # Stores true or false in integer if GNOME was installed
declare -l installedKDE=0 # Stores true or false in integer if KDE was installed
declare -l installedXFCE=0 # Stores true or false in integer if XFCE was installed
declare -l installedLXDE=0 # Stores true or false in integer if LXDE was installed
declare -l installedLXQT=0 # Stores true or false in integer if LXQT was installed
declare -l installedCINNAMON=0 # Stores true or false in integer if CINNAMON was installed
declare -l installedMATE=0 # Stores true or false in integer if MATE was installed
declare -i installedAllEnvironments=0 # Strores true or false as integer if all desktop environments were installed
declare -l -r scriptName="debian-install-desktop-environment-cli" # Stores script file name (Set to lowers and read-only)
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

# Function to display connection established message
function connEst(){
    dksay "GREEN" "\n Internet connection established!!\n" |& tee -a $logFileName
}

# Function to display connection failed message
function connFailed(){
    dksay "RED" "\n Internet connection failed!!\n" |& tee -a $logFileName
}

# Function to initiate logfile
function initLogFile(){
    cd ~ # Change directory to users' home directory
    rm -f $logFileName # Delete log file if/not it exists to prevent append to previous logs
    touch $logFileName # Creating log file
    currentDate="\n Date : `date` \n\n\n" # Get current date
    printf $currentDate &>> $logFileName # Log date without showing on terminal

    # Change to users' home directory to prevent installing some packages to unknown user directories
    dksay "YELLOW" "\n\n Changed directory to home directory." |& tee -a $logFileName
    sleep 3s # Hold for user to read
    dksay "YELLOW" "\n Created log file in `pwd` named \e[1;32m$logFileName\e[0m\n" |& tee -a $logFileName
    sleep 3s # Hold for user to read
    sectionBreak
}

# Function to fix any unmet dependencies and broken installs incase of network interruption
function checkDebugAndRollback(){

    if [ "$1" == '--debug' ]; then # Check for debug switch
        dksay "YELLOW" "\n Checking for errors and debugging. Please wait..." |& tee -a $logFileName
    elif [ "$1" == '--network' ]; then # Check for debug switch
        dksay "GREEN" "\n Debugging and rolling back some changes due to network interrupt.. Please wait..." |& tee -a $logFileName
    fi
    sleep 3s # Hold for user to read
    apt-get check |& tee -a $logFileName # Check for broken/unmet
    apt-get --fix-broken install |& tee -a $logFileName # Fix broken installs
    dpkg --configure -a |& tee -a $logFileName # Configure packages
    apt-get autoremove |& tee -a $logFileName # Remove un-used packages and dependencies
    apt-get autoclean |& tee -a $logFileName # Clean apt-get cache
    apt-get clean |& tee -a $logFileName # Clean disk space
    appstreamcli refresh --force |& tee -a $logFileName # Refresh appstream cache
    apt-file update |& tee -a $logFileName # apt-file update
    sleep 2s # Hold for user to read
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
                while [ "$date1" -ge `date +%s` ]; do
                  echo -ne " \e[1;32mRetrying connection after :\e[0m \e[1;33m$(date -u --date @$(($date1 - `date +%s`)) +%H:%M:%S)\r\e[0m" |& tee -a $logFileName
                  sleep 0.1
                done
            fi
        fi
        sleep 1 # hold loop
    done
}

# Function to exit script with custom coloured message
function exitScript(){
    dksay "RED" "\n\n Exiting script....\n\n" |& tee -a $logFileName # Display exit message
    sleep 3s # Hold for user to read

    if [ "$1" == '--end' ]; then # Check for --end switch
        # Check and debug any errors
        checkDebugAndRollback --debug

        cd ~ # Change to home directory
        dksay "YELLOW" "\n You can find this scripts log in \e[1;31m`pwd`\e[0m named $logFileName"
        sleep 1s # Hold for user to read

        # Draw logo
        dksay "GREEN" "\n\n       __   __\n      |  | |  |  ___\n      |  | |  | /  /\n    __|  | |  |/  /\n  /  _   | |     <\n |  (_|  | |  |\  \ \n  \______| |__| \__\ \n\n "
    elif [ "$1" == '--connectionFailure' ]; then
      dksay "RED"   "\n\n This script requires a stable internet connection to work fully!!" |& tee -a $logFileName
      dksay "GREEN" "\n Please check your connection settings and re-run the script.\n" |& tee -a $logFileName
      sleep 1s # Hold for user to read

      if [ "$2" == '--rollback' ]; then # Check for rollback switch
          # Initiate debug and rollback
          checkDebugAndRollback --network   # Check for and fix any broken installs or unmet dependencies
      fi
      dksay "YELLOW" "\n Please re-run script when there is a stable internet connection." |& tee -a $logFileName
      sleep 1s # Hold for user to read
    fi
    exit 0 # Exit script
}

# Function to check current desktop environment
function checkForDesktopEnvironment(){
    dksay "YELLOW" "\n Checking for desktop environment.." |& tee -a $logFileName
    sleep 3s
    if [ "$XDG_CURRENT_DESKTOP" = "" ]; then # Check for current desktop environment
        currentDesktopEnvironment=$(echo "$XDG_DATA_DIRS" | sed 's/.*\(xfce\|kde\|gnome\).*/\1/') # Test for XFCE, KDE and Gnome with GNU grep
    else currentDesktopEnvironment=$XDG_CURRENT_DESKTOP # Get XDG current desktop
    fi
    # Check if desktop environment was found
    if [ -z "$currentDesktopEnvironment" ]; then # (Variable empty) - Desktop environment not found
        dksay "GREEN" "\n No desktop environment found!!" |& tee -a $logFileName
    else dksay "GREEN" "\n Current desktop environment : $currentDesktopEnvironment" |& tee -a $logFileName # Display choice
    fi
}

# Function to query if user wants to install another desktop environment after installing the previous
# This is for users who want to install some but not all desktop environments
function queryInstallAnotherDesktopEnvironment(){
    while true; do # Start infinite loop
        # Prompt user to set GNOME desktop as default
        dksay "YELLOW" "\n Would you like to install another desktop environment?\n\t1. Y (Yes) - to install another.\n\t2. N (No) to cancel." |& tee -a $logFileName
        read -p ' option: ' qryChoice
        qryChoice=${qryChoice,,} # Convert to lowercase
        dksay "GREEN" " You chose : $qryChoice" |& tee -a $logFileName # Display choice

        if  [[ "$qryChoice" == 'yes' || "$qryChoice" == 'y' || "$qryChoice" == '1' ]]; then # Option : Yes
            return $(true) # Exit loop returning true
        elif [[ "$qryChoice" == 'no' || "$qryChoice" == 'n' || "$qryChoice" == '2' ]]; then # Option : No
            return $(false) # Exit loop returning false
        else dksay "GREEN" "\n Invalid entry!! Please try again." |& tee -a $logFileName # Invalid entry
        fi
        sleep 1 # hold loop
    done
}

# Function to install GNOME desktop environment
function installGNOMEDesktop(){
    # Checking for internet connection before continuing
    if isConnected; then # Internet connection Established
        dksay "YELLOW" "\n\n Installing GNOME. This may take a while depending on your internet connection. Please wait..." |& tee -a $logFileName
        sleep 6s # Hold for user to read
        if [ "$1" == '--y' ]; then # Check for yes switch to install without confirmation
            apt-get install gnome -y |& tee -a $logFileName # Install full gnome with confirmation
        else apt-get install gnome |& tee -a $logFileName # Install full gnome without confirmation
        fi
        dksay "YELLOW" "\n\n Installing alacarte - Alacarte is a menu editor for the GNOME desktop, written in Python" |& tee -a $logFileName
        sleep 5s # Hold for user to read
        apt-get install alacarte |& tee -a $logFileName # Install alacarte
        dksay "GREEN" "\n GNOME installation complete." |& tee -a $logFileName
        sleep 2s # Hold for user to read
        dksay "YELLOW" "\n Checking if gdm3 is installed. If not it will be installed." |& tee -a $logFileName
        sleep 5s # Hold for user to read
        apt-get install gdm3 |& tee -a $logFileName # Install gdm3 if id does not exist

        # Check for GNOME setDefault switch
        if [ "$1" == '--setDefault' ]; then
            dksay "YELLOW" "\n Setting GNOME as default desktop environment." |& tee -a $logFileName
            sleep 5s # Hold for user to read
            dpkg-reconfigure gdm3 |& tee -a $logFileName
            cat /etc/X11/default-display-manager |& tee -a $logFileName # Display set default desktop environment
        else # Let user decide
            while true; do
                # Prompt user to set GNOME desktop as default
                dksay "YELLOW" "\n Would you like to set GNOME as yout default desktop environment?\n\t1. Y (Yes) - to set default.\n\t2. N (No) to cancel or skip." |& tee -a $logFileName
                read -p ' option: ' dfChoice
                dfChoice=${dfChoice,,} # Convert to lowercase
                dksay "GREEN" " You chose : $dfChoice" |& tee -a $logFileName # Display choice

                if  [[ "$dfChoice" == 'yes' || "$dfChoice" == 'y' || "$dfChoice" == '1' ]]; then # Option : Yes
                    dksay "YELLOW" "\n Setting GNOME as default desktop environment." |& tee -a $logFileName
                    sleep 5s # Hold for user to read
                    dpkg-reconfigure gdm3 |& tee -a $logFileName
                    cat /etc/X11/default-display-manager |& tee -a $logFileName # Display set default desktop environment
                    break # Break from loop
                elif  [[ "$dfChoice" == 'no' || "$dfChoice" == 'n' || "$dfChoice" == '2' ]]; then # Option : No
                    dksay "NC" "\n Skipped..." |& tee -a $logFileName
                    break # Break from loop
                else dksay "GREEN" "\n Invalid entry!! Please try again." |& tee -a $logFileName # Invalid entry
                fi
                sleep 1 # hold loop
            done
        fi
        installedGNOME=$[installedGNOME + 1] # Set GNOME installed to true
        dksay "GREEN" "\n Your GNOME Desktop is all set." |& tee -a $logFileName
        sectionBreak
    else # Internet connection failed
        exitScript --connectionFailure # Exit script on connection failure
    fi
}

# Function to install KDE desktop environment
function installKDEDesktop(){
    # Checking for internet connection before continuing
    if isConnected; then # Internet connection Established
        dksay "YELLOW" "\n\n Installing KDE Plasma Desktop. This may take a while depending on your internet connection. Please wait..." |& tee -a $logFileName
        sleep 6s # Hold for user to read
        if [ "$1" == '--y' ]; then # Check for yes switch to install without confirmation
            apt-get install kde-standard -y |& tee -a $logFileName # Install KDE without confirmation
        else
            apt-get install kde-standard |& tee -a $logFileName # Install KDE with confirmation
        fi
        installedKDE=$[installedKDE + 1] # Set KDE installed to true
        dksay "GREEN" "\n Your KDE Plasma Desktop is all set." |& tee -a $logFileName
        dksay "YELLOW" "\n Checking for the default desktop environment." |& tee -a $logFileName
        cat /etc/X11/default-display-manager |& tee -a $logFileName # Display set default desktop environment
        sleep 4s # Hold for user to read
        sectionBreak
    else # Internet connection failed
        exitScript --connectionFailure # Exit script on connection failure
    fi
}

# Function to install XFCE desktop environment
function installXFCEDesktop(){
    # Checking for internet connection before continuing
    if isConnected; then # Internet connection Established
        dksay "YELLOW" "\n\n Installing XFCE Desktop. This may take a while depending on your internet connection. Please wait..." |& tee -a $logFileName
        sleep 6s # Hold for user to read
        if [ "$1" == '--y' ]; then # Check for yes switch to install without confirmation
            apt-get install xfce4 -y |& tee -a $logFileName # Install XFCE4 with confirmation
        else
            apt-get install xfce4 |& tee -a $logFileName # Install XFCE4 without confirmation
        fi
        installedXFCE=$[installedXFCE + 1] # Set XFCE installed to true
        dksay "GREEN" "\n Your XFCE Desktop is all set." |& tee -a $logFileName
        dksay "YELLOW" "\n Checking for the default desktop environment." |& tee -a $logFileName
        cat /etc/X11/default-display-manager |& tee -a $logFileName # Display set default desktop environment
        sleep 4s # Hold for user to read
        sectionBreak
    else # Internet connection failed
          exitScript --connectionFailure # Exit script on connection failure
    fi
}

# Function to install LXDE desktop environment
function installLXDEDesktop(){
    # Checking for internet connection before continuing
    if isConnected; then # Internet connection Established
        dksay "YELLOW" "\n\n Installing LXDE Desktop. This may take a while depending on your internet connection. Please wait..." |& tee -a $logFileName
        sleep 6s # Hold for user to read
        if [ "$1" == '--y' ]; then # Check for yes switch to install without confirmation
            apt-get install lxde -y |& tee -a $logFileName # Install LXDE desktop environment with confirmation
        else apt-get install lxde |& tee -a $logFileName # Install LXDE desktop environment without confirmation
        fi
        installedLXDE=$[installedLXDE + 1] # Set LXDE installed to true
        dksay "GREEN" "\n Your LXDE Desktop is all set." |& tee -a $logFileName
        dksay "YELLOW" "\n Checking for the default desktop environment." |& tee -a $logFileName
        cat /etc/X11/default-display-manager |& tee -a $logFileName # Display set default desktop environment
        sleep 4s # Hold for user to read
        sectionBreak
    else # Internet connection failed
      exitScript --connectionFailure # Exit script on connection failure
    fi
}

# Function to install LXQT desktop environment
function installLXQTDesktop(){
    # Checking for internet connection before continuing
    if isConnected; then # Internet connection Established
        dksay "YELLOW" "\n\n Installing LXQT Desktop. This may take a while depending on your internet connection. Please wait..." |& tee -a $logFileName
        sleep 6s # Hold for user to read
        if [ "$1" == '--y' ]; then # Check for yes switch to install without confirmation
            apt-get install lxqt -y |& tee -a $logFileName # Install LXQT desktop environment with confirmation
        else apt-get install lxqt |& tee -a $logFileName # Install LXQT desktop environment without confirmation
        fi
        installedLXQT=$[installedLXQT + 1] # Set LXQT installed to true
        dksay "GREEN" "\n Your LXQT Desktop is all set." |& tee -a $logFileName
        dksay "YELLOW" "\n Checking for the default desktop environment." |& tee -a $logFileName
        cat /etc/X11/default-display-manager |& tee -a $logFileName # Display set default desktop environment
        sleep 4s # Hold for user to read
        sectionBreak
    else # Internet connection failed
      exitScript --connectionFailure # Exit script on connection failure
    fi
}

# Function to install CINNAMON desktop environment
function installCinnamonDesktop(){
    # Checking for internet connection before continuing
    if isConnected; then # Internet connection Established
        dksay "YELLOW" "\n\n Installing Cinnamon Desktop. This may take a while depending on your internet connection. Please wait..." |& tee -a $logFileName
        sleep 6s # Hold for user to read
        if [ "$1" == '--y' ]; then # Check for yes switch to install without confirmation
            apt-get install cinnamon-desktop-environment -y |& tee -a $logFileName # Install cinnamon desktop environment with confirmation
        else apt-get install cinnamon-desktop-environment |& tee -a $logFileName # Install cinnamon desktop environment without confirmation
        fi
        installedCINNAMON=$[installedCINNAMON + 1] # Set CINNAMON installed to true
        dksay "GREEN" "\n Your Cinnamon Desktop is all set." |& tee -a $logFileName
        dksay "YELLOW" "\n Checking for the default desktop environment." |& tee -a $logFileName
        cat /etc/X11/default-display-manager |& tee -a $logFileName # Display set default desktop environment
        sleep 4s # Hold for user to read
        sectionBreak
    else # Internet connection failed
          exitScript --connectionFailure # Exit script on connection failure
    fi
}

# Function to install MATE desktop environment
function installMateDesktop(){
    # Checking for internet connection before continuing
    if isConnected; then # Internet connection Established
        dksay "YELLOW" "\n\n Installing Mate Desktop. This may take a while depending on your internet connection. Please wait..." |& tee -a $logFileName
        sleep 6s # Hold for user to read
        if [ "$1" == '--y' ]; then # Check for yes switch to install without confirmation
            apt-get install task-mate-desktop -y |& tee -a $logFileName # Install mate desktop environment with confirmation
        else apt-get install task-mate-desktop |& tee -a $logFileName # Install mate desktop environment without confirmation
        fi
        installedMATE=$[installedMATE + 1] # Set MATE installed to true
        dksay "GREEN" "\n Your Mate Desktop is all set." |& tee -a $logFileName
        dksay "YELLOW" "\n Checking for the default desktop environment." |& tee -a $logFileName
        cat /etc/X11/default-display-manager |& tee -a $logFileName # Display set default desktop environment
        sleep 4s # Hold for user to read
        sectionBreak
    else # Internet connection failed
          exitScript --connectionFailure # Exit script on connection failure
    fi
}

# Function to install all desktop environments
function installAllDesktopEnvironments(){
    # Install all desktop environments
    installKDEDesktop --y # Install KDE Desktop
    installXFCEDesktop --y # Install XFCE Desktop
    installLXDEDesktop --y # Install LXDE Desktop
    installLXQTDesktop --y # Install LXQT Desktop
    installCinnamonDesktop --y # Install CINNAMON Desktop
    installMateDesktop --y # Install MATE Desktop
    installGNOMEDesktop --setDefault # Install GNOME Desktop and set it as the default desktop

    # Check if all desktop environments were installed
    if [[ "$installedKDE" -eq 1 && "$installedXFCE" -eq 1 && "$installedLXDE" -eq 1 && "$installedLXQT" -eq 1 && "$installedCINNAMON" -eq 1
          && "$installedMATE" -eq 1 && "$installedGNOME" -eq 1 ]];
    then # Installed all desktop environment
        installedAllEnvironments=$[installedAllEnvironments + 1] # Set installed all to true using integer
    fi
}

# Function to install desktop environment
function installDesktopEnvironment(){
    declare -l reEnteredChoice="false"
    while true; do # Start infinite loop
        if [ "$reEnteredChoice" == 'false' ]; then
        dksay "YELLOW" "\n Please select the desktop environment to install from the options below."
        sleep 4s # Hold for user to read
        dksay "NC" "
        \t\e[1;32m1. GNOME \e[0m: (gdm3)
                    \n\t\tGNOME is noteworthy for its efforts in usability and accessibility. Design professionals have been involved
                    in writing standards and recommendations. This has helped developers to create satisfying graphical user interfaces.
                    For administrators, GNOME seems to be better prepared for massive deployments. Many programming languages can be used
                    in developing applications interfacing to GNOME."
        sleep 1s # Hold for user to read
        dksay "NC" "
        \t\e[1;32m2. KDE PLASMA\e[0m: (sddm)
                    \n\t\tKDE has had a rapid evolution based on a very hands-on approach.
                    KDE is a perfectly mature desktop environment with a wide range of applications."
        sleep 1s # Hold for user to read
        dksay "NC" "
        \t\e[1;32m3. XFCE \e[0m: (lightdm)
                    \n\t\tXfce is a simple and lightweight graphical desktop, a perfect match for computers with limited resources.
                    Xfce is based on the GTK+ toolkit, and several components are common across both desktops but does not aim at
                    being a vast project. Beyond the basic components of a modern desktop, it only provides a few specific
                    applications: a terminal, a calendar (Orage), an image viewer, a CD/DVD burning tool, a media player (Parole),
                    sound volume control and a text editor (mousepad)."
        sleep 1s # Hold for user to read
        dksay "NC" "
        \t\e[1;32m4. LXDE \e[0m:
                    \n\t\tLXDE is written in the C programming language, using the GTK+ 2 toolkit, and runs on Unix and
                    other POSIX-compliant platforms, such as Linux and BSDs. The LXDE project aims to provide a fast
                    and energy-efficient desktop environment with low memory usage."
        sleep 1s # Hold for user to read
        dksay "NC" "
        \t\e[1;32m5. LXQT \e[0m:
                    \n\t\tLXQt is an advanced, easy-to-use, and fast desktop environment based on Qt technologies. It has been
                    tailored for users who value simplicity, speed, and an intuitive interface. Unlike most desktop environments,
                    LXQt also works fine with less powerful machines."
        sleep 1s # Hold for user to read
        dksay "NC" "
        \t\e[1;32m6. CINNAMON \e[0m:
                    \n\t\tCinnamon is a free and open-source desktop environment for the X Window System that derives from GNOME 3 but follows
                    traditional desktop metaphor conventions. Cinnamon is the principal desktop environment of the Linux Mint distribution and
                    is available as an optional desktop for other Linux distributions and other Unix-like operating systems as well."
        sleep 1s # Hold for user to read
        dksay "NC" "
        \t\e[1;32m7. Mate \e[0m:
                    \n\t\tThe MATE Desktop Environment is the continuation of GNOME 2. It provides an intuitive and attractive desktop environment
                    using traditional metaphors for Linux and other Unix-like operating systems. MATE is under active development to add support
                    for new technologies while preserving a traditional desktop experience. Mate feels old school."
        sleep 1s # Hold for user to read
        dksay "NC" "
        \t\e[1;32m8. Install all of them \e[0m: This will set GNOME as your default desktop environment."
        sleep 1s # Hold for user to read
        dksay "NC" "
        \t\e[1;32m9. To Skip / Cancel \e[0m: This will skip desktop environment installation."
        sleep 1s

        read -p ' option: ' choice
        choice=${choice,,} # Convert to lowercase
        dksay "GREEN" " You chose : $choice" |& tee -a $logFileName # Display choice
        fi
        # Check chosen option
        if  [[ "$choice" == '1' || "$choice" == 'gnome' ]]; then # Option : Yes
            # Check if desktop environment value was is empty
            # This is for those who had installed some desktop environment.
            # This ensures that they are not forced to make GNOME as their default if they were running any other desktop environment
            # This stage will be skipped if another desktop environment was found during check.
            if [ -z "$currentDesktopEnvironment" ]; then # (Variable empty) - Desktop environment not found
                installGNOMEDesktop --setDefault # Install GNOME Desktop and set it as the default desktop
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
        elif  [[ "$choice" == '2' || "$choice" == 'kde' || "$choice" == 'kde plasma' || "$choice" == 'kdeplasma' || "$choice" == 'kde-plasma' ]]; then # Option : KDE
            installKDEDesktop # Install KDE Desktop

            # Query if user wants to install another desktop environment after installing the previous
            if queryInstallAnotherDesktopEnvironment; then # Installation of another desktop environment - true
                sleep 1 # Hold loop
                continue # Resume iterations
            else # Installation of another desktop environment - false
                break # Break from loop
            fi
        elif  [[ "$choice" == '3' || "$choice" == 'xfce' ]]; then # Option : XFCE
            installXFCEDesktop # Install XFCE Desktop

            # Query if user wants to install another desktop environment after installing the previous
            if queryInstallAnotherDesktopEnvironment; then # Installation of another desktop environment - true
                sleep 1 # Hold loop
                continue # Resume iterations
            else # Installation of another desktop environment - false
                break # Break from loop
            fi
        elif  [[ "$choice" == '4' || "$choice" == 'lxde' ]]; then # Option : LXDE
            installLXDEDesktop # Install LXDE Desktop

            # Query if user wants to install another desktop environment after installing the previous
            if queryInstallAnotherDesktopEnvironment; then # Installation of another desktop environment - true
                sleep 1 # Hold loop
                continue # Resume iterations
            else # Installation of another desktop environment - false
                break # Break from loop
            fi
          elif  [[ "$choice" == '5' || "$choice" == 'lxqt' ]]; then # Option : LXDE
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
        elif  [[ "$choice" == '7' || "$choice" == 'mate' ]]; then # Option : MATE
            installMateDesktop # Install Mate Desktop

            # Query if user wants to install another desktop environment after installing the previous
            if queryInstallAnotherDesktopEnvironment; then # Installation of another desktop environment - true
                sleep 1 # Hold loop
                continue # Resume iterations
            else # Installation of another desktop environment - false
                break # Break from loop
            fi
        elif  [[ "$choice" == '8' || "$choice" == 'install all of them' || "$choice" == 'install all' || "$choice" == 'all' ]]; then
            installAllDesktopEnvironments # Install all desktop environments
            break # Break from loop
        elif  [[ "$choice" == '9' || "$choice" == 'skip' || "$choice" == 'cancel' || "$choice" == 'exit' ]]; then
            dksay "RED" "\n Setup cancelled!!" |& tee -a $logFileName
            sleep 1s # Hold for user to read
            break # Break from loop
        else
          # Invalid entry
          dksay "GREEN" "\n Invalid desktop selection!! Please try again." |& tee -a $logFileName

          # Re-enter choice
          read -p ' option: ' choice
          choice=${choice,,} # Convert to lowercase
          dksay "GREEN" "You chose : $choice" # Display choice
          reEnteredChoice="true"
        fi
        sleep 1 # hold loop
    done
}

########
# Beginning of script
########
initLogFile # Initiate log file

dksay "RED" 		"\n\n Hello there user $USER. \n" |& tee -a $logFileName
dksay "YELLOW"	" This script will help you install some or all listed desktop environments into your debian or ubuntu linux.\n" |& tee -a $logFileName
sleep 13s # Hold for user to read

# Check if user is running as root
declare -l user=$USER # Declare user variable as lowercase
if [ "$user" != 'root' ]; then
      dksay "YELLOW" "\n This script works best when run as root.\n Please run it as root if you encounter any issues.\n" |& tee -a $logFileName
      sleep 3s # Hold for user to read
fi
sectionBreak

dksay "GREEN" " Script     : $scriptName"
dksay "GREEN" " Version    : 2.0.0" |& tee -a $logFileName
dksay "GREEN" " License    : MIT" |& tee -a $logFileName
dksay "GREEN" " Author     : David Kariuki (dk)\n" |& tee -a $logFileName

dksay "GREEN" "\n Initializing script...!!\n" |& tee -a $logFileName
sleep 3s # Hold for user to read

# Checking for internet connection before continuing
if ! isConnected; then # Internet connection failed
  exitScript --connectionFailure # Exit script on connection failure
fi

# Check and debug any errors
checkDebugAndRollback --debug

# Check for desktop environment
checkForDesktopEnvironment

# Show install desktop environment options
installDesktopEnvironment

# Exit script
exitScript --end |& tee -a $logFileName
sleep 3s # Hold for user to read

# Restart desktop environments services
if [ "$installedAllEnvironments" -eq 1 ]; then # Gnome is default
    dksay "YELLOW" "Restarting gdm3 service."
    sleep 2s # Hold for user to read
    systemctl restart gdm3 |& tee -a $logFileName # Start / restart gdm3
elif [[ "$installedKDE" -eq 1 && "$installedXFCE" -eq 0 && "$installedLXDE" -eq 0 && "$installedCINNAMON" -eq 0 && "$installedMATE" -eq 0 && "$installedGNOME" -eq 0 ]]; then
    dksay "YELLOW" "Restarting sddm service."
    sleep 2s # Hold for user to read
    systemctl restart gdm3 |& tee -a $logFileName # Start / restart sddm
fi
# Restart
#GNOME  - gdm3 -
#KDE    - sddm
#XFCE   - lightdm
