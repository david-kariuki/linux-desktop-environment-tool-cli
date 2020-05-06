#!/bin/bash
declare -i currentDesktopEnvironment="" # Stores the value of the current installed desktop environment
declare -l selectedDesktopEnvironment="" # Stores the value of the last selected desktop environment
declare -l installedAllEnvironments=0 # Strores true or false as integer if all desktop environments were installed
declare -l -r scriptName="debian-install-desktop-environment-cli" # Stores script file name (Set to lowers and read-only)
declare -l -r logFileName="$scriptName-logs.txt" # Stores script log-file name (Set to lowers and read-only)
declare -l -r networkTestUrl=www.google.com # Stores the networkTestUrl (Set to lowers and read-only)

# Common code docs
# dksay - Custom function to create a custom coloured print
# |& tee -a $logFileName - append output stream to logs and output to terminal

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
    # Print without color3
    dksay "NC" "......\n\n" |& tee -a $logFileName
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
    dksay "YELLOW" "\n Created log file in `pwd` named $logFileName.\n" |& tee -a $logFileName
    sleep 3s # Hold for user to read
    sectionBreak
}

# Function to fix any unmet dependencies and broken installs incase of network interruption
function checkDebugAndRollback(){

    if [ "$1" == '--debug' ]; then # Check for debug switch
        dksay "GREEN" "\n Checking for errors and debugging. Please wait..." |& tee -a $logFileName
    elif [ "$1" == '--network' ]; then # Check for debug switch
        dksay "GREEN" "\n Debugging and rolling back some changes due to network interrupt.. Please wait..." |& tee -a $logFileName
    fi
    sleep 3s # Hold for user to read
    apt-get check |& tee -a $logFileName
    apt-get --fix-broken install |& tee -a $logFileName
    dpkg --configure -a |& tee -a $logFileName
    apt-get autoremove |& tee -a $logFileName
    apt-get autoclean |& tee -a $logFileName
    apt-get clean |& tee -a $logFileName
    appstreamcli refresh --force |& tee -a $logFileName
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
	          $1 $2 == "SSLhandshake" { handshake = 1 }'; then # Internet connection established

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

    if [ "$1" == '--end']; then # Check for --end switch
        # Draw logo
        dksay "GREEN" "\n\n      __   __\n     |  | |  |  ___\n     |  | |  | /  /\n   __|  | |  |/  /\n /  _   | |     <\n|  (_|  | |  |\  \ \n \______| |__| \__\ \n\n " |& tee -a $logFileName

        cd ~ # Change to home directory
        dksay "YELLOW" "\n You can find this scripts log in `pwd` named $logFileName"
        sleep 1s # Hold for user to read
    else
      dksay "YELLOW" "\n Please re-run script when there is a stable internet connection"
      sleep 3s # Hold for user to read
    fi
    exit 0 # Exit script
}

# Function to exit on connection failure
function exitOnConnectionFailure(){
    dksay "RED"   "\n\n This script requires a stable internet connection to work fully!!" |& tee -a $logFileName
    dksay "GREEN" "\n Please check your connection settings and re-run the script.\n" |& tee -a $logFileName

    if [ "$1" == '--rollback' ]; then # Check for rollback option
        # Initiate debug and rollback
        checkDebugAndRollback --network   # Check for and fix any broken installs or unmet dependencies
        exitScript # Exit script
    fi
}

# Function to check current desktop environment
function checkForDesktopEnvironment(){
    dksay "YELLOW" "\n Checking for desktop environment.."
    sleep 3s
    if [ "$XDG_CURRENT_DESKTOP" = "" ]; then # Check for current desktop environment

        desktopEnv=$(echo "$XDG_DATA_DIRS" | sed 's/.*\(xfce\|kde\|gnome\).*/\1/') # Test for XFCE, KDE and Gnome with GNU grep
    else
        desktopEnv=$XDG_CURRENT_DESKTOP
    fi
    currentDesktopEnvironment=${desktopEnv,,}  # Convert to lower case and set value to global variable
}

# Function to query if user wants to install another desktop environment after installing the previous
# This is for users who want to install some but not all desktop environments
function queryInstallAnotherDesktopEnvironment(){
    while true; do # Start infinite loop
        # Prompt user to set GNOME desktop as default
        dksay "YELLOW" "\n Would you like to install another desktop environment?\n\t1. Y (Yes) - to install another.\n\t2. N (No) to cancel." |& tee -a $logFileName
        read -p ' option: ' choice  # |& tee -a $logFileName
        choice=${choice,,} # Convert to lowercase
        dksay "GREEN" " You chose : $choice" |& tee -a $logFileName # Display choice

        if  [[ "$choice" == 'yes' || "$choice" == 'y' || "$choice" == '1' ]]; then # Option : Yes
            sectionBreak
            return $(true) # Exit loop returning true

        elif  [[ "$choice" == 'no' || "$choice" == 'n' || "$choice" == '2' || "$choice" == 'cancel' ]]; then # Option : No
            return $(false) # Exit loop returning false

        else # Invalid entry
            dksay "GREEN" "\n Invalid entry!! Please try again." |& tee -a $logFileName
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
        apt-get install gnome |& tee -a $logFileName # Install full gnome
        dksay "YELLOW" "\n\n Installing alacarte - Alacarte is a menu editor for the GNOME desktop, written in Python" |& tee -a $logFileName
        sleep 5s # Hold for user to read
        apt-get install alacarte |& tee -a $logFileName # Install alacarte
        dksay "GREEN" "\n GNOME installation complete." |& tee -a $logFileName
        sleep 2s # Hold for user to read
        dksay "YELLOW" "\n Checking if gdm3 is installed. If not it will be installed." |& tee -a $logFileName
        sleep 5s # Hold for user to read
        apt-get install gdm3 |& tee -a $logFileName # Install gdm3 if id does not exist

        # Check for GNOME setDefault switch
        if [ "$1" == '--setDefault']; then
            dksay "YELLOW" "\n Setting GNOME as default desktop environment." |& tee -a $logFileName
            sleep 5s # Hold for user to read
            dpkg-reconfigure gdm3 |& tee -a $logFileName
            cat /etc/X11/default-display-manager |& tee -a $logFileName # Display set default desktop environment

        else # Let user decide
            while true; do
                # Prompt user to set GNOME desktop as default
                dksay "YELLOW" "\n Would you like to set GNOME as yout default desktop environment?\n\t1. Y (Yes) - to set default.\n\t2. N (No) to cancel or skip." |& tee -a $logFileName
                read -p ' option: ' choice  # |& tee -a $logFileName
                choice=${choice,,} # Convert to lowercase
                dksay "GREEN" " You chose : $choice" |& tee -a $logFileName # Display choice

                if  [[ "$choice" == 'yes' || "$choice" == 'y' || "$choice" == '1' ]]; then # Option : Yes
                    dksay "YELLOW" "\n Setting GNOME as default desktop environment." |& tee -a $logFileName
                    sleep 5s # Hold for user to read
                    dpkg-reconfigure gdm3 |& tee -a $logFileName
                    cat /etc/X11/default-display-manager |& tee -a $logFileName # Display set default desktop environment

                elif  [[ "$choice" == 'no' || "$choice" == 'n' || "$choice" == '2' ]]; then # Option : No
                    dksay "NC" "\n Skipped..." |& tee -a $logFileName
                else # Invalid entry
                    dksay "GREEN" "\n Invalid entry!! Please try again." |& tee -a $logFileName
                fi
                sleep 1 # hold loop
            done
        fi

        sksay "GREEN" "\n Your GNOME Desktop is all set." |& tee -a $logFileName
        selectedDesktopEnvironment="gnome" # Update selected desktop environment value
        sectionBreak

        # Query if user wants to install another desktop environment after installing the previous
        if ! queryInstallAnotherDesktopEnvironment; then # Installation of another desktop environment cancelled
            break # Break from loop
        fi
    else # Internet connection failed
        exitOnConnectionFailure # Exit script
    fi
}

# Function to install KDE desktop environment
function installKDEDesktop(){
    # Checking for internet connection before continuing
    if isConnected; then # Internet connection Established
        dksay "YELLOW" "\n\n Installing KDE Plasma Desktop. This may take a while depending on your internet connection. Please wait..." |& tee -a $logFileName
        sleep 6s # Hold for user to read
        apt-get install kde-standard # Install KDE
        sksay "GREEN" "\n Your KDE Plasma Desktop is all set." |& tee -a $logFileName
        selectedDesktopEnvironment="kde" # Update selected desktop environment value
        dksay "YELLOW" "\n Below is the default desktop environment." |& tee -a $logFileName
        cat /etc/X11/default-display-manager |& tee -a $logFileName # Display set default desktop environment
        sleep 4s # Hold for user to read
        sectionBreak

        # Query if user wants to install another desktop environment after installing the previous
        if ! queryInstallAnotherDesktopEnvironment; then # Installation of another desktop environment cancelled
            break # Break from loop
        fi
    else # Internet connection failed
        exitOnConnectionFailure # Exit script
    fi
}

# Function to install XFCE desktop environment
function installXFCEDesktop(){
    # Checking for internet connection before continuing
    if isConnected; then # Internet connection Established
        dksay "YELLOW" "\n\n Installing XFCE Desktop. This may take a while depending on your internet connection. Please wait..." |& tee -a $logFileName
        sleep 6s # Hold for user to read
        apt-get install xfce4 |& tee -a $logFileName # Install XFCE4
        sksay "GREEN" "\n Your XFCE Desktop is all set." |& tee -a $logFileName
        selectedDesktopEnvironment="xfce" # Update selected desktop environment value
        dksay "YELLOW" "\n Below is the default desktop environment." |& tee -a $logFileName
        cat /etc/X11/default-display-manager |& tee -a $logFileName # Display set default desktop environment
        sleep 4s # Hold for user to read
        sectionBreak

        # Query if user wants to install another desktop environment after installing the previous
        if ! queryInstallAnotherDesktopEnvironment; then # Installation of another desktop environment cancelled
            break # Break from loop
        fi
    else # Internet connection failed
          exitOnConnectionFailure # Exit script
    fi
}

# Function to install LXDE desktop environment
function installLXDEDesktop(){
    # Checking for internet connection before continuing
    if isConnected; then # Internet connection Established
        dksay "YELLOW" "\n\n Installing LXDE Desktop. This may take a while depending on your internet connection. Please wait..." |& tee -a $logFileName
        sleep 6s # Hold for user to read
        apt-get install lxde # Install LXDE desktop environment
        sksay "GREEN" "\n Your LXDE Desktop is all set." |& tee -a $logFileName
        selectedDesktopEnvironment="lxde" # Update selected desktop environment value
        dksay "YELLOW" "\n Below is the default desktop environment." |& tee -a $logFileName
        cat /etc/X11/default-display-manager |& tee -a $logFileName # Display set default desktop environment
        sleep 4s # Hold for user to read
        sectionBreak

        # Query if user wants to install another desktop environment after installing the previous
        if ! queryInstallAnotherDesktopEnvironment; then # Installation of another desktop environment cancelled
            break # Break from loop
        fi
    else # Internet connection failed
      exitOnConnectionFailure # Exit script
    fi
}

# Function to install CINNAMON desktop environment
function installCinnamonDesktop(){
    # Checking for internet connection before continuing
    if isConnected; then # Internet connection Established
        dksay "YELLOW" "\n\n Installing Cinnamon Desktop. This may take a while depending on your internet connection. Please wait..." |& tee -a $logFileName
        sleep 6s # Hold for user to read
        apt-get install cinnamon-desktop-environment |& tee -a $logFileName # Install cinnamon desktop environment
        sksay "GREEN" "\n Your Cinnamon Desktop is all set." |& tee -a $logFileName
        selectedDesktopEnvironment="cinnamon" # Update selected desktop environment value
        dksay "YELLOW" "\n Below is the default desktop environment." |& tee -a $logFileName
        cat /etc/X11/default-display-manager |& tee -a $logFileName # Display set default desktop environment
        sleep 4s # Hold for user to read
        sectionBreak

        # Query if user wants to install another desktop environment after installing the previous
        if ! queryInstallAnotherDesktopEnvironment; then # Installation of another desktop environment cancelled
            break # Break from loop
        fi
    else # Internet connection failed
          exitOnConnectionFailure # Exit script
    fi
}

# Function to install MATE desktop environment
function installMateDesktop(){
    # Checking for internet connection before continuing
    if isConnected; then # Internet connection Established
        dksay "YELLOW" "\n\n Installing Mate Desktop. This may take a while depending on your internet connection. Please wait..." |& tee -a $logFileName
        sleep 6s # Hold for user to read
        apt-get install task-mate-desktop |& tee -a $logFileName # Install mate desktop environment
        sksay "GREEN" "\n Your Mate Desktop is all set." |& tee -a $logFileName
        selectedDesktopEnvironment="mate" # Update selected desktop environment value
        dksay "YELLOW" "\n Below is the default desktop environment." |& tee -a $logFileName
        cat /etc/X11/default-display-manager |& tee -a $logFileName # Display set default desktop environment
        sleep 4s # Hold for user to read
        sectionBreak

        # Query if user wants to install another desktop environment after installing the previous
        if ! queryInstallAnotherDesktopEnvironment; then # Installation of another desktop environment cancelled
            break # Break from loop
        fi
    else # Internet connection failed
          exitOnConnectionFailure # Exit script
    fi
}

# Function to install desktop environment
function installDesktopEnvironment(){

    dksay "YELLOW" "\n Please select the desktop environment to install from the options below."
    dksay "NC" "
    \n\t\e[1;32m1. GNOME \e[0m:
                \n\t\tGNOME is noteworthy for its efforts in usability and accessibility. Design professionals have been involved
                in writing standards and recommendations. This has helped developers to create satisfying graphical user interfaces.
                For administrators, GNOME seems to be better prepared for massive deployments. Many programming languages can be used
                in developing applications interfacing to GNOME.
    \n\t\e[1;32m2. KDE PLASMA\e[0m:
                \n\t\tKDE has had a rapid evolution based on a very hands-on approach.
                KDE is a perfectly mature desktop environment with a wide range of applications.
    \n\t\e[1;32m3. XFCE \e[0m:
                \n\t\tXfce is a simple and lightweight graphical desktop, which is a perfect match for computers with limited resources.
                Xfce is based on the GTK+ toolkit, and several components are common across both desktops but does not aim at being a vast
                project. Beyond the basic components of a modern desktop (file manager, window manager, session manager, a panel for
                application launchers and so on), it only provides a few specific applications: a terminal, a calendar (Orage), an image
                viewer, a CD/DVD burning tool, a media player (Parole), sound volume control and a text editor (mousepad).
    \n\t\e[1;32m4. LXDE \e[0m:
                \n\t\tLXDE is written in the C programming language, using the GTK+ 2 toolkit, and runs on Unix and
                other POSIX-compliant platforms, such as Linux and BSDs. The LXDE project aims to provide a fast
                and energy-efficient desktop environment. It has low memory usage.
    \n\t\e[1;32m5. CINNAMON \e[0m:
                \n\t\tCinnamon is a free and open-source desktop environment for the X Window System that derives from GNOME 3
                but follows traditional desktop metaphor conventions. Cinnamon is the principal desktop environment of the Linux Mint distribution
                and is available as an optional desktop for other Linux distributions and other Unix-like operating systems as well.
    \n\t\e[1;32m6. Mate \e[0m:
                \n\t\tThe MATE Desktop Environment is the continuation of GNOME 2. It provides an intuitive and attractive desktop environment
                using traditional metaphors for Linux and other Unix-like operating systems. MATE is under active development to add support
                for new technologies while preserving a traditional desktop experience. Mate feels old school.
    \n\t\e[1;32m7. Install all of them \e[0m: This will set GNOME as your default desktop environment.
    \n\t\e[1;32m8. To Skip / Cancel \e[0m: This will skip desktop environment installation.
                \n Respond with \n\t\e[1;32m1 or gnome\e[0m - to install GNOME.
                \n\t\e[1;32m2 \e[0m - to install KDE.
                \n\t\e[1;32m3 \e[0m - to install XFCE.
                \n\t\e[1;32m4 \e[0m - to install LXDE.
                \n\t\e[1;32m5 \e[0m - to install CINNAMON.
                \n\t\e[1;32m6 \e[0m - to install MATE.
                \n\t\e[1;32m7 \e[0m - to install all of them.
                \n\t\e[1;32m8 \e[0m - to cancel installation.
    " |& tee -a $logFileName
    read -p ' option: ' choice  # |& tee -a $logFileName
    choice=${choice,,} # Convert to lowercase
    dksay "GREEN" " You chose : $choice" |& tee -a $logFileName # Display choice

    while true; do # Start infinite loop

        # Check chosen option
        if  [[ "$choice" == '1' || "$choice" == 'gnome' ]]; then # Option : Yes
            # Check if desktop environment value was is empty
            # This is for those who had installed some desktop environment.
            # This ensures that they are not forced to make GNOME as their default if they were running any other desktop environment
            # This stage will be skipped if another desktop environment was found during check.
            if [ -z "$currentDesktopEnvironment" ]; then # Desktop environment not found
                installGNOMEDesktop --setDefault # Install GNOME Desktop and set it as the default desktop
            else
                installGNOMEDesktop # Install GNOME Desktop
            fi
        elif  [[ "$choice" == '2' || "$choice" == 'kde' || "$choice" == 'kde plasma' || "$choice" == 'kdeplasma' || "$choice" == 'kde-plasma' ]]; then # Option : KDE
            installKDEDesktop # Install KDE Desktop

        elif  [[ "$choice" == '3' || "$choice" == 'xfce' ]]; then # Option : XFCE
            installXFCEDesktop # Install XFCE Desktop

        elif  [[ "$choice" == '4' || "$choice" == 'lxde' ]]; then # Option : LXDE
            installLXDEDesktop # Install LXDE Desktop

        elif  [[ "$choice" == '5' || "$choice" == 'cinnamon' || "$choice" == 'cinamon' ]]; then # Option : Cinnamon
            installCinnamonDesktop # Install Cinnamon Desktop

        elif  [[ "$choice" == '6' || "$choice" == 'mate' ]]; then # Option : MATE
            installMateDesktop # Install Mate Desktop

        elif  [[ "$choice" == '7' || "$choice" == 'install all of them' || "$choice" == 'install all' || "$choice" == 'all' ]]; then

            installedAllEnvironments=$[installedAllEnvironments + 1] # Set installed all to true using integer
            installGNOMEDesktop --setDefault # Install GNOME Desktop and set it as the default desktop
            installKDEDesktop
            installXFCEDesktop
            installLXDEDesktop
            installCinnamonDesktop
            installMateDesktop

        elif  [[ "$choice" == '8' || "$choice" == 'skip' || "$choice" == 'cancel' || "$choice" == 'exit' ]]; then
            dksay "RED" " \nSetup cancelled. Exiting..." |& tee -a $logFileName
            sleep 3s # Hold for user to read
            # Exit script
            exitScript --end |& tee -a $logFileName
        else
          # Invalid entry
          dksay "GREEN" "\n Invalid entry!! Please try again." |& tee -a $logFileName

          # Re-enter choice
          read -p ' option: ' choice  # |& tee -a $logFileName
          choice=${choice,,} # Convert to lowercase
          dksay "GREEN" "You chose : $choice" # Display choice
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
sleep 15s # Hold for user to read

# Check if user is running as root
user=$USER
user=${user,,} # Convert to lowercase
if [ "$user" != 'root' ]; then

      dksay "YELLOW" "\n This script works best when run as root.\n Please run it as root if you encounter any issues.\n" |& tee -a $logFileName
      sleep 3s # Hold for user to read
fi
sectionBreak

dksay "GREEN" " Script     : $scriptName"
dksay "GREEN" " Version    : 2.0.0" |& tee -a $logFileName
dksay "GREEN" " License    : MIT\n" |& tee -a $logFileName
dksay "GREEN" " Author     : David Kariuki (dk)" |& tee -a $logFileName

dksay "GREEN" "\n Initializing script...!!\n" |& tee -a $logFileName
sleep 3s # Hold for user to read

# Checking for internet connection before continuing
if ! isConnected; then # Internet connection failed
  exitOnConnectionFailure # Exit script
fi

# Check and debug any errors
checkDebugAndRollback --debug

# Show install desktop environment options
installDesktopEnvironment

# Exit script
exitScript --end |& tee -a $logFileName
