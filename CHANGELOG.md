# CHANGELOG
**linux-desktop-environment-tool-cli**

\
**Changelog from version 1.0 - 4.0**

**Version 1.0:**
1. Added options to install:
   - `GNOME` Desktop environment.
   - `KDE PLASMA` Desktop environment.
   - `XFCE` Desktop environment.
   - `LXDE` Desktop environment.
   - `LXQT` Desktop environment.
   - `CINNAMON` Desktop environment.
   - `MATE` Desktop environment.

**Version 1.1:**
1. Added function to setup, enable and start desktop environment automatically after installation of a desktop environment   for users who initially, did not have any desktop environment installed."

**Version 1.2:**
1. Changed KDE installation from standard installation to full installation.
2. Fixed some bugs including one that made installing all desktop environments a problem.

**Version 2.0:**
  1. Added options to install:
     - `BUDGIE` Desktop environment.
     - `ENLIGHTENMENT` Desktop environment.

**Version 3.0:**
  1. Added options to install:
     - `KODI` Desktop environment.

**Version 3.1:**
1. Added feature to install `X Window Server`.
2. Logs feature bug fixes.
3. Changed name from `debian-install-desktop-environment-cli.sh` to `debian-desktop-environment-manager-cli.sh`

**Version 3.2:**
1. Added feature to install missing desktop environments base packages and some extras.

**Version 3.3:**
1. Added feature to uninstall existing desktop environments.
2. Bug fixes that caused the script to run upgrades and updates when the script was canceled.

**Version 3.4:**
1. Added feature to indicate if the desktop environments on the installation lists have already been installed.
2. Bug fixes:
   - Bugs that prevented `LXDE` desktop environment from being listed on the uninstallation list.
   - Bugs that prevented automation of the `uninstall all option` to run continuously without single desktop manual purge confirmations.

**Version 3.5:**
1. Changed name from `debian-desktop-environment-manager-cli.sh` to `linux-desktop-environment-toolkit-cli.sh`
2. Minor refactoring.

**Version 3.6:**
1. Added function to check for and install linux headers before installing desktop environments.
2. Bug fixes and code optimization.

**Version 4.0:**
1. Added option to install and install `Fluxbox`.
2. Removed `Kodi` from list of desktop environments.
3. Reduced script execution time taken by long sleep timers.
4. Other minor fixes and improvements.
