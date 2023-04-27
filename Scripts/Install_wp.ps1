# .Synopsis
#   Easy Wordpress Installer.

# .Description
#   Quick and Easy Download and Installation of WP
# * Just place this file to the directory where you want to install wordpress
# * and then browse the file (./installer.php) using any browser.
# * The files will be downloaded and you will be moved to the setup page
# .NOTES
#   Place into the root folder where you want to install wordpress and
#   Browse the file from any browser. It will download the latest wordpress and move you to the setup page.
#   Isn't it just too easy?
# Requirements:
#   PHP 5 >= 5.2.0 or PHP 7. PHP needs to have the zip extension installed.
param()
$IsPHPinstalled = Get-Command php -ErrorAction Ignore
if ($IsPHPinstalled) {
    php ./Install_wp.php
}