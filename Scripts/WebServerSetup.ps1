<#
.SYNOPSIS
    PHP WebServerSetup
.DESCRIPTION
    A PowerShell script that installs the Web Server, Web CGI & IIS management tools roles,
    installs and configures PHP including the wincache dll, configures IIS for PHP and creates an index.php file preconfigured with phpinfo():
.NOTES
    Information or caveats about the function e.g. 'This function is not supported in Linux'
.LINK
    https://learn.microsoft.com/en-us/iis/web-hosting/web-server-for-shared-hosting/installing-the-web-server-role
.LINK
    https://stackoverflow.com/questions/37892173/automating-installation-of-iis
.LINK
    https://www.rootusers.com/how-to-install-iis-in-windows-server-2019/
.EXAMPLE
    Test-MyTestFunction -Verbose
    Explanation of the function or its result. You can include multiple examples with additional .EXAMPLE lines
#>
param (
    [switch]$reboot,
    [switch]$Force
)

begin {
    $ErrorActionPreference = 'Stop'
    #Requires -RunAsAdministrator
    if ($null -ne ${env:=::}) { Throw 'Please Run this as Administrator' }

    function private:Install-PHP {
        # .LINK
        #  Modern setup example: https://www.sitepoint.com/docker-php-development-environment/
        # .EXAMPLE
        # $Installer = New-Object PHPInstaller
        # $Installer.UseThreadSafe = $true
        # $Installer.Install()
        param (
            [Parameter(Mandatory = $false)]
            [psobject]$InstallConfig = [pscustomobject]@{
                info          = @{
                    server        = @{
                        supported_version = "1.0"
                    }
                    php           = @{
                        version           = "7.4.0"
                        filename          = "php-7.4.0.tar.gz"
                        install_directory = "/usr/local/php"
                    }
                    wincache      = @{
                        version = "2.0.0.8"
                    }
                    vc_redist_x64 = @{
                        version      = "14.28.29913"
                        filename     = "vc_redist.x64.exe"
                        display_name = "Microsoft Visual C++ 2015-2019 Redistributable (x64) - 14.28.29913"
                    }
                    iis           = @{
                        del_default_site = $false
                        site_name        = "Default Web Site"
                        site_path        = "C:\inetpub\wwwroot"
                    }
                }
                UseThreadSafe = $true
                DontAddToPath = $false
            }
        )

    }
    class PHPInstaller {
        [string]$bldDir
        [bool]$Force
        hidden [string]$releases = 'http://windows.php.net/download'

        PHPInstaller() {}

        [void] Install() {
            $this.Install()
        }
        [void] Install([version]$version) {

            #region Install&ConfigurePHP
            $xml = $null
            # Extract PHP
            try {
                Write-Host -f green "[INFO] Extracting $($xml.info.php.filename) to $($xml.info.php.install_directory)"
                Expand-Archive -LiteralPath $this.bldDir\$($xml.info.php.filename) -DestinationPath $($xml.info.php.install_directory) -Force -ErrorAction SilentlyContinue
                Write-Host -f green "[INFO] Extracted $($xml.info.php.filename) to $($xml.info.php.install_directory)"
            } catch {
                Write-Host -f red "[ERROR] Extraction of PHP zip file failed. Script terminated."
                Write-Host -f red "[ERROR] $($_.exception.message)"
                Break
            }

            # Copy PHP.ini
            try {
                Write-Host -f green "[INFO] Copying php.ini file to $($xml.info.php.install_directory)"
                Copy-Item -LiteralPath $this.bldDir\$($xml.info.php.php_ini) -Destination "$($xml.info.php.install_directory)\php.ini" -Force -ErrorAction SilentlyContinue
                Write-Host -f green "[INFO] Copied php.ini file to $($xml.info.php.install_directory)"
            } catch {
                Write-Host -f red "[ERROR] Copying PHP.ini failed. Script terminated."
                Write-Host -f red "[ERROR] $($_.exception.message)"
                Break
            }

            # Set extension_dir in php.ini
            $date = (Get-Date -Format (Get-Culture).DateTimeFormat.ShortDatePattern)
            $user = $env:USERDOMAIN + "\" + $env:USERNAME
            $script = $MyInvocation.MyCommand.Name
            $a = "extension_dir = `"<<ToBeReplacedByScript>>`""
            $b = "; Modified on $date by $user using $script`r`nextension_dir = `"$($xml.info.php.install_directory)\ext`""

            # Search php.ini for extension_dir
            if (Select-String -Path "$($xml.info.php.install_directory)\php.ini" -Pattern $a -ErrorAction SilentlyContinue) {
                Write-Host -f green "[INFO] PHP.ini extension_dir parameter needs configured."

                try {
                    Write-Host -f green "[INFO] Configuring extension_dir in PHP.ini."
                    (Get-Content -Path $($xml.info.php.install_directory + "\php.ini") -Raw -Force -ErrorAction SilentlyContinue) -replace $a, $b | Set-Content -Path $($xml.info.php.install_directory + "\php.ini") -Force -ErrorAction SilentlyContinue
                    Write-Host -f green "[INFO] Configured extension_dir in PHP.ini."
                } catch {
                    Write-Host -f red "[ERROR] Configuring extension_dir in PHP.ini failed. Script terminated."
                    Write-Host -f red "[ERROR] $($_.exception.message)"
                    Break
                }

            } else {
                Write-Host -f green "[INFO] PHP.ini extension_dir parameter already configured."
            }

            # Configure Environmental Variable Path
            try {
                Write-Host -f green "[INFO] Adding $($xml.info.php.install_directory) to the path environmental variable."
                $curPath = (Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Environment' -Name Path -ErrorAction SilentlyContinue).Path

                # If value is already there then skip otherwise set variable
                if ($curPath -like "*$($xml.info.php.install_directory)") {
                    Write-Host -f green "[INFO] $($xml.info.php.install_directory) already exists in the path environmental variable."
                } else {
                    $newPath = $curPath + ";" + $($xml.info.php.install_directory)
                    Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Environment' -Name Path -Value $newPath
                    Write-Host -f green "[INFO] Added $($xml.info.php.install_directory) to the path environmental variable."
                }

            } catch {
                Write-Host -f red "[ERROR] Unable to add to the path environmental variable. Script terminated."
                Write-Host -f red "[ERROR] $($_.exception.message)"
                Break
            }

            # Copy WinCache DLL
            try {
                Write-Host -f green "[INFO] Copying $this.bldDir\$($xml.info.wincache.filename) to $($xml.info.php.install_directory)"
                Copy-Item -LiteralPath $this.bldDir\$($xml.info.wincache.filename) -Destination "$($xml.info.php.install_directory)\Ext" -Force -ErrorAction SilentlyContinue
                Write-Host -f green "[INFO] Copied $this.bldDir\$($xml.info.wincache.filename) to $($xml.info.php.install_directory)"
            } catch {
                Write-Host -f red "[ERROR] Unable to copy $($xml.info.wincache.filename) to $($xml.info.php.install_directory)\Ext. Script terminated."
                Write-Host -f red "[ERROR] $($_.exception.message)"
                Break
            }
            #endregion Install&ConfigurePHP
            # --------------------------------------

            $installLocation = $this.Get_InstallLocation()

            if ($this.Force) {
                if ($installLocation.Exists) {
                    Write-Host "Uninstalling previous version of php..."
                    $pathToRemove = $installLocation.FullName
                    Uninstall-ChocolateyPath $installLocation
                    # Remove it from Path and UpdateSessionEnvVariabes
                    $envPath = $env:PATH
                    if ($envPath.ToLower().Contains($pathToRemove.ToLower())) {
                        Write-Host "The PATH environment variable contains the directory '$pathToRemove'; Removing..."
                        $pathType = [System.EnvironmentVariableTarget]::Process # (generate this)
                        $actualPath = [Environment]::GetEnvironmentVariable('Path', $pathType)
                        $newPath = $actualPath -replace [regex]::Escape($pathToRemove + ';'), '' -replace ';;', ';'

                        if (($pathType -eq [System.EnvironmentVariableTarget]::Machine) -and !(Test-ProcessAdminRights)) {
                            Write-Warning "Removing path from machine environment variable is not supported when not running as an elevated user!"
                        } else {
                            Set-EnvironmentVariable -Name 'Path' -Value $newPath -Scope $pathType
                        }
                        $env:PATH = $newPath
                    }
                }

            }


            $filesInfo = @{
                filets32  = "$installLocation\php-8.2.5-Win32-vs16-x86.zip"
                filets64  = "$installLocation\php-8.2.5-Win32-vs16-x64.zip"
                filents32 = "$installLocation\php-8.2.5-nts-Win32-vs16-x86.zip"
                filents64 = "$installLocation\php-8.2.5-nts-Win32-vs16-x64.zip"
            }

            if ($this.UseThreadSafe) {
                $file32 = $filesInfo.filets32
                $file64 = $filesInfo.filets64
            } else {
                $file32 = $filesInfo.filents32
                $file64 = $filesInfo.filents64
            }

            $packageArgs = @{
                packageName = $env:ChocolateyPackageName
                file        = $file32
                file64      = $file64
            }

            $newInstallLocation = $packageArgs.Destination = $this.Get_InstallLocation()

            Get-ChocolateyUnzip @packageArgs

            Get-ChildItem $installLocation\*.zip | ForEach-Object { Remove-Item $_ -ea 0; if (Test-Path $_) { Set-Content "$_.ignore" } }

            if (!$this.DontAddToPath) { Install-ChocolateyPath $newInstallLocation 'Machine' }

            $php_ini_path = $newInstallLocation + '/php.ini'

            if (($installLocation -ne $newInstallLocation) -and (Test-Path "$installLocation\php.ini")) {
                Write-Host "Moving old configuration file."
                Move-Item "$installLocation\php.ini" "$php_ini_path"

                $di = Get-ChildItem $installLocation -ea 0 | Measure-Object
                if ($di.Count -eq 0) {
                    Write-Host "Removing old install location."
                    Remove-Item -Force -ea 0 $installLocation
                }
            }

            if (!(Test-Path $php_ini_path)) {
                Write-Host 'Creating default php.ini'
                Copy-Item $newInstallLocation/php.ini-production $php_ini_path

                Write-Host 'Configuring PHP extensions directory'
            (Get-Content $php_ini_path) -replace ';\s?extension_dir = "ext"', 'extension_dir = "ext"' | Set-Content $php_ini_path
            }

            if (!$this.UseThreadSafe) { Write-Host 'Please make sure you have CGI installed in IIS for local hosting' }
        }
        [System.Object] GetLatestVersion() {
            return $this.GetLatestVersion($this.releases)
        }
        [System.Object] GetLatestVersion([string]$releases) {
            [ValidateNotNullOrEmpty()][string]$releases = $releases
            $download_page = Invoke-WebRequest -Uri $releases -UseBasicParsing

            $url32Bits = $download_page.links | Where-Object href -Match 'nts.*x86\.zip$' | Where-Object href -NotMatch 'debug|devel' | Select-Object -expand href
            $url64Bits = $download_page.links | Where-Object href -Match 'nts.*x64\.zip$' | Where-Object href -NotMatch 'debug|devel' | Select-Object -expand href

            $streams = @{ }

            $null = ($url32Bits | Sort-Object).Foreach({
                    $version = $_ -split '-' | Select-Object -First 1 -Skip 1
                    $url64Bit = $url64Bits | Where-Object { $_ -split '-' | Select-Object -First 1 -Skip 1 | Where-Object { $_ -eq $version } }

                    $streams.Add((Get-Version $version).ToString(2), ($this.CreateStream($_, $url64Bit, $version)));

                }
            )
            return @{ Streams = $streams }
        }
        [System.Object] CreateStream([uri]$url32Bit, [uri]$url64bit, [version]$version) {
            $Result = @{
                Version      = $version
                URLNTS32     = 'http://windows.php.net' + $url32bit
                URLNTS64     = 'http://windows.php.net' + $url64bit
                URLTS32      = 'http://windows.php.net' + ($url32bit | ForEach-Object { $_ -replace '\-nts', '' })
                URLTS64      = 'http://windows.php.net' + ($url64bit | ForEach-Object { $_ -replace '\-nts', '' })
                ReleaseNotes = "https://www.php.net/ChangeLog-$($version.Major).php#${version}"
                Dependency   = $this.Get_Dependency($url32Bit)
            }

            if ($Result.URLNTS32 -eq $Result.TS32) {
                throw "The threadsafe and non-threadsafe 32bit url is equal... This is not expected"
            }

            if ($Result.URLNTS64 -eq $Result.TS64) {
                throw "The threadsafe and non-threadsafe 64bit url is equal... This is not expected"
            }
            return $Result
        }
        hidden [System.Object] Get_Dependency([uri]$url) {
            $dep = $url -split '\-' | Select-Object -Last 1 -Skip 1
            $result = @{
                'vs16' = @{ Id = 'vcredist140'; Version = '14.28.29325.2' };
                'vc15' = @{ Id = 'vcredist140'; Version = '14.16.27012.6' }
                'vc14' = @{ Id = 'vcredist140'; Version = '14.0.24215.1' }
                'vc11' = @{ Id = 'vcredist2012'; Version = '11.0.61031' }
            };
            $result.GetEnumerator() | Where-Object Key -EQ $dep | Select-Object -First 1 -expand Value

            if (!$result) {
                throw "VC Redistributable version was not found. Please check the script."
            }
            return $result
        }

        [IO.DirectoryInfo] Get_InstallLocation([string]$libDirectory) {
            $location = $null
            Write-Debug "Checking for uninstall text document in $libDirectory"

            if (Test-Path "$libDirectory\*.txt") {
                $txtContent = Get-Content -Encoding UTF8 "$libDirectory\*.txt" | Select-Object -First 1
                $index = $txtContent.LastIndexOf('\')
                if ($index -gt 0) {
                    $location = $txtContent.Substring(0, $index)
                }
            }
            return $location
            # If we got here, the text file doesn't exist or is empty
            # we don't return anything as it may be already uninstalled
        }
    }
    function private:CheckRequiements {
        param ()

        # Verify build package exists
        if (!(Test-Path $bldPkg -Include *.zip)) {
            Write-Host -f red "[ERROR] Build package $bldPkg was  not found. Script terminated."
            Break
        } else {
            Write-Host -f green "[INFO] Build package $bldPkg found."
        }

        # Extract Build Package
        try {
            $bldFolder = (Split-Path $bldPkg -Leaf -ErrorAction SilentlyContinue) -replace ".zip", ""
            $this.bldDir = (Split-Path $bldPkg -Parent -ErrorAction SilentlyContinue) + "\" + $bldFolder
            Write-Host -f green "[INFO] Extracting $bldPkg to $this.bldDir"
            Expand-Archive -LiteralPath $bldpKg -DestinationPath $this.bldDir -Force -ErrorAction SilentlyContinue
            Write-Host -f green "[INFO] Extracted $bldPkg to $this.bldDir"
        } catch {
            Write-Host -f red "[ERROR] Extraction of the build package failed. Script terminated."
            Write-Host -f red "[ERROR] $($_.exception.message)"
            Break
        }

        # Verify xml report file exists
        if (!(Test-Path "$this.bldDir\Config.xml" -Include *.xml)) {
            Write-Host -f red "[ERROR] Configuration xml file $this.bldDir\Config.xml was not found. Script terminated."
            Break
        } else {
            Write-Host -f green "[INFO] Configuration xml file $this.bldDir\Config.xml found."
        }

        # Read config xml file
        try {
            Write-Host -f green "[INFO] Reading contents of $this.bldDir\Config.xml."
            [xml]$xml = Get-Content -Path "$this.bldDir\Config.xml" -ErrorAction SilentlyContinue
        } catch {
            Write-Host -f red "[ERROR] Unable to open $this.bldDir\Config.xml. Script terminated."
            Write-Host -f red "[ERROR] $($_.exception.message)"
            Break
        }

        # Verify config is valid. Each config item
        $xml.info.server.supported_version # server/supported_version.
        $xml.info.php.version # php/version
        $xml.info.php.filename
        $xml.info.php.install_directory
        $xml.info.wincache.version
        $xml.info.wincache.version
        $xml.info.vc_redist_x64.version
        $xml.info.vc_redist_x64.filename
        $xml.info.vc_redist_x64.display_name
        $xml.info.iis.del_default_site # maybe this is a boolean
        $xml.info.iis.del_default_site
        $xml.info.iis.site_name
        $xml.info.iis.site_path

        # Get Server OS
        try {
            Write-Host -f green "[INFO] Getting Operating System details from registry."
            $reg = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey('LocalMachine', $endpoint)
            $key = "SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion"
            $openSubKey = $reg.OpenSubKey($key)
            Write-Host -f green "[INFO] Operating System is $($openSubKey.getvalue("ProductName"))."

            # Check if supported OS
            if ($openSubKey.getvalue("ProductName") -like "*$(($xml.info.server.supported_version))*") {
                Write-Host -f green "[INFO] Operarting System is supported."
            } else {
                Write-Host -f red "[ERROR] Operarting System is not supported. Script terminated."
                Break
            }

        } catch {
            Write-Host -f red "[ERROR] Unable to get Operating System details from registry. Script terminated."
            Break
        }

        # Check PHP File Exists
        if (!(Test-Path $this.bldDir\$($xml.info.php.filename))) {
            Write-Host -f red "[ERROR] $($xml.info.php.filename) was not found in $this.bldDir. Script terminated."
            Break
        } else {
            Write-Host -f green "[INFO] $($xml.info.php.filename) present."
        }

        # Verify PHP Hash
        try {
            $hash = (Get-FileHash -Path $this.bldDir\$($xml.info.php.filename) -Algorithm SHA256 -ErrorAction SilentlyContinue).hash

            if ($xml.info.php.sha256 -eq $hash) {
                Write-Host -f green "[INFO] $($xml.info.php.filename) file hash verified."
            } else {
                Write-Host -f red "[ERROR] $($xml.info.php.filename) file hash check failed. Script terminated."
                Break
            }

        } catch {
            Write-Host -f red "[ERROR] Unable to get file hash of $($xml.info.php.filename). Script terminated."
            Write-Host -f red "[ERROR] $($_.exception.message)"
            Break
        }

        # Check PHP.ini Exists
        if (!(Test-Path $this.bldDir\$($xml.info.php.php_ini))) {
            Write-Host -f red "[ERROR] $($xml.info.php.php_ini) was not found in $this.bldDir. Script terminated."
            Break
        } else {
            Write-Host -f green "[INFO] $($xml.info.php.php_ini) present."
        }

        # Verify PHP.ini Hash
        try {
            $hash = (Get-FileHash -Path $this.bldDir\$($xml.info.php.php_ini) -Algorithm SHA256 -ErrorAction SilentlyContinue).hash

            if ($xml.info.php.php_ini_sha256 -eq $hash) {
                Write-Host -f green "[INFO] $($xml.info.php.php_ini) file hash verified."
            } else {
                Write-Host -f red "[ERROR] $($xml.info.php.php_ini) file hash check failed. Script terminated."
                Break
            }

        } catch {
            Write-Host -f red "[ERROR] Unable to get file hash of $($xml.info.php.php_ini). Script terminated."
            Write-Host -f red "[ERROR] $($_.exception.message)"
            Break
        }

        # Check WinCache File Exists
        if (!(Test-Path $this.bldDir\$($xml.info.wincache.filename))) {
            Write-Host -f red "[ERROR] $($xml.info.wincache.filename) was not found in $this.bldDir. Script terminated."
            Break
        } else {
            Write-Host -f green "[INFO] $($xml.info.wincache.filename) present."
        }

        # Verify WinCache Hash
        try {
            $hash = (Get-FileHash -Path $this.bldDir\$($xml.info.wincache.filename) -Algorithm SHA256 -ErrorAction SilentlyContinue).hash

            if ($xml.info.wincache.sha256 -eq $hash) {
                Write-Host -f green "[INFO] $($xml.info.wincache.filename) file hash verified."
            } else {
                Write-Host -f red "[ERROR] $($xml.info.wincache.filename) file hash check failed. Script terminated."
                Break
            }

        } catch {
            Write-Host -f red "[ERROR] Unable to get file hash of $($xml.info.wincache.filename). Script terminated."
            Write-Host -f red "[ERROR] $($_.exception.message)"
            Break
        }

        # Check VC Redist x64 File Exists
        if (!(Test-Path $this.bldDir\$($xml.info.vc_redist_x64.filename))) {
            Write-Host -f red "[ERROR] $($xml.info.vc_redist_x64.filename) was not found in $this.bldDir. Script terminated."
            Break
        } else {
            Write-Host -f green "[INFO] $($xml.info.vc_redist_x64.filename) present."
        }

        # Verify VC Redist x64 Hash
        try {
            $hash = (Get-FileHash -Path $this.bldDir\$($xml.info.vc_redist_x64.filename) -Algorithm SHA256 -ErrorAction SilentlyContinue).hash

            if ($xml.info.vc_redist_x64.sha256 -eq $hash) {
                Write-Host -f green "[INFO] $($xml.info.vc_redist_x64.filename) file hash verified."
            } else {
                Write-Host -f red "[ERROR] $($xml.info.vc_redist_x64.filename) file hash check failed. Script terminated."
                Break
            }

        } catch {
            Write-Host -f red "[ERROR] Unable to get file hash of $($xml.info.vc_redist_x64.filename). Script terminated."
            Write-Host -f red "[ERROR] $($_.exception.message)"
            Break
        }
    }
    function private:InstallVCRedist {
        # .DESCRIPTION
        #  Installs the latest version of visual-c-redist
        # .LINK
        # https://learn.microsoft.com/en-us/cpp/windows/latest-supported-vc-redist
        # https://learn.microsoft.com/en-us/cpp/windows/redistributing-visual-cpp-files?view=msvc-170
        # https://superuser.com/questions/1709790/how-to-find-direct-download-links-to-older-specific-version-of-visual-c-redist
        param ()
        try {
            $url = "https://aka.ms/vs/17/release/vc_redist.x64.exe"
            $output = "vc_redist.x64.exe"
            Invoke-WebRequest -Uri $url -OutFile $output
            Start-Process -FilePath $output -ArgumentList "/install", "/quiet", "/norestart"
            Remove-Item $output
            Write-Host -f green "[INFO] Installing Visual C++ Redistributable (x64)."
            $filename = $this.bldDir + "\" + $($xml.info.vc_redist_x64.filename)
            Invoke-Command -ScriptBlock { Start-Process $filename -ArgumentList "/quiet /norestart" -Wait } -ErrorAction SilentlyContinue
            # No complete message as it will be displayed below once install checked.
        } catch {
            Write-Host -f red "[ERROR] Unable to install Visual C++ Redistributable (x64). Script terminated."
            Write-Host -f red "[ERROR] $($_.exception.message)"
            Break
        }

        # PowerShell doesn't handle exit codes in exe's well. So adding in a further check
        try {
            $isInstalled = "No"
            Write-Host -f green "[INFO] Checking Visual C++ Redistributable (x64) is installed."
            $reg = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey('LocalMachine', $env:COMPUTERNAME)
            $key = "SOFTWARE\\WOW6432Node\\Microsoft\\Windows\\CurrentVersion\\Uninstall"
            $openSubKey = $reg.OpenSubKey($key)
            $subKeys = $openSubKey.GetSubKeyNames()

            foreach ($subKey in $subKeys) {

                # Set to Yes if display name is in the registry (Add/remove programs)
                if ((($reg.OpenSubKey($key + "\\" + $subKey).getValue('DisplayName')) -replace ",", ";") -eq $xml.info.vc_redist_x64.display_name) {
                    $isInstalled = "Yes"
                }

            }

            if ($isInstalled -eq 'Yes') {
                Write-Host -f green "[INFO] Visual C++ Redistributable (x64) is installed."
            } else {
                Write-Host -f red "[ERROR] Visual C++ Redistributable (x64) is not installed. Script terminated."
                Break
            }

        } catch {
            Write-Host -f red "[ERROR] Unable determine if Visual C++ Redistributable (x64) is installed. Script terminated."
            Write-Host -f red "[ERROR] $($_.exception.message)"
            Break
        }
    }
    function private:ConfigureIIS {
        param ()
        # Create IIS data folder
        New-Item -ItemType Directory -Path ($($xml.info.iis.site_path) + "\" + $($xml.info.iis.site_name))

        # Delete IIS default site, if requested in config file
        if ($xml.info.iis.del_default_site -eq 'Yes') {

            try {
                Write-Host -f green "[INFO] Deleting IIS Default Website."
                Remove-Website -Name "Default Web Site" -ErrorAction SilentlyContinue
                Write-Host -f green "[INFO] Deleted IIS Default Website."
            } catch {
                Write-Host -f red "[ERROR] Unable to delete IIS default website. Script terminated."
                Write-Host -f red "[ERROR] $($_.exception.message)"
                Break
            }

        }

        # Create new IIS site
        try {
            Write-Host -f green "[INFO] Creating IIS Website $($xml.info.iis.site_name)."
            [void](New-Website -Name $($xml.info.iis.site_name) -PhysicalPath $($xml.info.iis.site_path) -Force -ErrorAction SilentlyContinue)
            Write-Host -f green "[INFO] Created IIS Website $($xml.info.iis.site_name)."
        } catch {
            Write-Host -f red "[ERROR] Unable to create IIS website $($xml.info.iis.site_name). Script terminated."
            Write-Host -f red "[ERROR] $($_.exception.message)"
            Break
        }

        # IIS: Unlock global config (config editor > system.webServer/handlers)
        try {
            Write-Host -f green "[INFO] Unlocking IIS path at parent level."
            Set-WebConfiguration //System.webServer/handlers -metadata overrideMode -value Allow -PSPath IIS:/ -Force -ErrorAction SilentlyContinue
            Write-Host -f green "[INFO] Unlocked IIS path at parent level."
        } catch {
            Write-Host -f red "[ERROR] Unable to unlock IIS path at parent level. Script terminated."
            Write-Host -f red "[ERROR] $($_.exception.message)"
            Break
        }

        # Compose Web Handler name then create
        $wHname = "PHP $($xml.info.php.version)" -replace " ", ""
        $wHScriptProc = "$($xml.info.php.install_directory)\php-cgi.exe"

        # If Web Handler doesn't exist
        if (!(Get-WebHandler -Name $wHname -PSPath "IIS:\Sites\$($xml.info.iis.site_name)")) {

            # Create New Web Handler
            try {
                Write-Host -f green "[INFO] Creating IIS Web Handler for PHP."

                # When using New-WebHandler cmdlet, the Web Handler was being created successfully but a php page would not load, the following error would appear.
                # HTTP Error 500.21 - Internal Server Error
                # Handler "PHP7.4.1NTSx64" has a bad module "FastCGIModule" in its module list
                # If the Web Handler was created manually via the IIS GUI php would work.
                # Leaving command used for reference.
                #New-WebHandler -Name $wHname -Verb * -Path *.php -Modules FastCGIModule -ScriptProcessor $wHScriptProc -PSPath "IIS:\Sites\$($xml.info.iis.site_name)" -ResourceType Either -RequiredAccess Script -Force -ErrorAction SilentlyContinue

                Add-WebConfiguration "System.WebServer/Handlers" -PSPath "IIS:\Sites\$($xml.info.iis.site_name)" -Value @{
                    Name            = $wHname;
                    Path            = "*.php";
                    Verb            = "*";
                    Modules         = "FastCgiModule";
                    ScriptProcessor = $wHScriptProc;
                    ResourceType    = 'Either';
                    RequireAccess   = 'Script'
                } -Force -ErrorAction SilentlyContinue

                Write-Host -f green "[INFO] Created IIS Web Handler for PHP."
            } catch {
                Write-Host -f red "[ERROR] Unable to create Web Handler for PHP in IIS. Script terminated."
                Write-Host -f red "[ERROR] $($_.exception.message)"
                Break
            }

        } else {
            Write-Host -f green "[INFO] IIS Web Handler for PHP already exists."
        }

        # Create FastCgi application. If app doesn't exist, create it
        if (!(Get-WebConfiguration "System.WebServer/FastCgi/Application" -ErrorAction SilentlyContinue | Where-Object { $_.fullPath -eq $wHScriptProc })) {

            # Add FastCgi application
            try {
                Write-Host -f green "[INFO] Creating FastCgi application for PHP."
                Add-WebConfiguration "System.WebServer/FastCgi" -Value @{'fullPath' = $wHScriptProc } -Force -ErrorAction SilentlyContinue
                Write-Host -f green "[INFO] Created FastCgi application for PHP."
            } catch {
                Write-Host -f red "[ERROR] Unable to create FastCgi application for PHP in IIS. Script terminated."
                Write-Host -f red "[ERROR] $($_.exception.message)"
                Break
            }

        } else {
            Write-Host -f green "[INFO] FastCgi Application for PHP already exists."
        }

        # NOT NEEDED AS WILL STOP IIS WORKING (as message below).
        # Error 500.19
        # This configuration section cannot be used at this path. This happens when the section is locked at a parent level.
        # Locking is either by default (overrideModeDefault="Deny"), or set explicitly by a location tag with overrideMode="Deny" or the legacy allowOverride="false".
        # IIS: Lock global config (config editor > system.webServer/handlers)
        #try{
        #Write-Host -f green "[INFO] Locking IIS path at parent level."
        #Set-WebConfiguration //System.webServer/handlers -metadata overrideMode -value Deny -PSPath IIS:/ -Force -ErrorAction SilentlyContinue
        #Write-Host -f green "[INFO] Locked IIS path at parent level."
        #}
        #catch{
        #Write-Host -f red "[ERROR] Unable to Lock IIS path at parent level. Script terminated."
        #Write-Host -f red "[ERROR] $($_.exception.message)"
        #Break
        #}

        # Create index.php
        try {
            $file = $($xml.info.iis.site_path) + "\" + $($xml.info.iis.site_name) + "\index.php"
            $tab = "`t"

            if (Test-Path -PathType Leaf -Path $file -ErrorAction SilentlyContinue) {
                Write-Host -f green "[INFO] File index.php already exists, deleting file."
                Remove-Item -Path $file -Force -ErrorAction SilentlyContinue
                Write-Host -f green "[INFO] File index.php deleted."
            }

            Write-Host -f green "[INFO] Creating index.php file in $($xml.info.iis.site_path)"
            Add-Content $file "<?php" -Force -ErrorAction SilentlyContinue
            Add-Content $file "$tab`phpinfo();" -Force -ErrorAction SilentlyContinue
            Add-Content $file "?>" -Force -ErrorAction SilentlyContinue
            Write-Host -f green "[INFO] Created index.php file in $($xml.info.iis.site_path)"
        } catch {
            Write-Host -f red "[ERROR] Unable to delete/create index.php file. Script terminated."
            Write-Host -f red "[ERROR] $($_.exception.message)"
            Break
        }

        # Stop/Start Website
        try {
            Write-Host -f green "[INFO] Restarting IIS Site $($xml.info.iis.site_name)."
            Stop-Website -Name $($xml.info.iis.site_name) -ErrorAction SilentlyContinue
            Start-Website -Name $($xml.info.iis.site_name) -ErrorAction SilentlyContinue
            Write-Host -f green "[INFO] Restarted IIS Site $($xml.info.iis.site_name)."
        } catch {
            Write-Host -f red "[ERROR] Unable to Stop/Start IIS site $($xml.info.iis.site_name). Script terminated."
            Write-Host -f red "[ERROR] $($_.exception.message)"
            Break
        }
    }
}
process {
    # Install Web Server Role
    Install-WindowsFeature -Name Web-Server -IncludeManagementTools

    # Install CGI Role
    Install-WindowsFeature -Name Web-CGI

    # Install IIS Management Tools Role
    Install-WindowsFeature -Name Web-Mgmt-Tools

    # Install PHP
    Invoke-WebRequest -Uri "https://windows.php.net/downloads/releases/php-8.0.14-nts-Win32-vs16-x64.zip" -OutFile "C:\php.zip"
    Expand-Archive -Path "C:\php.zip" -DestinationPath "C:\php"
    Copy-Item -Path "C:\php\php.ini-development" -Destination "C:\php\php.ini"
    Add-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST' -filter "system.webServer/handlers" -name "." -value @{path = '*.php'; verb = 'GET,HEAD,POST'; modules = 'FastCgiModule'; scriptProcessor = 'C:\php\php-cgi.exe'; resourceType = 'Either'; requireAccess = 'Script' }

    # Configure IIS for PHP
    Set-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST' -filter "system.webServer/fastCGI" -name "." -value @{fullPath = 'C:\php\php-cgi.exe' }
    Set-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST' -filter "system.webServer/fastCGI/application" -name "." -value @{fullPath = 'C:\php\php-cgi.exe' }
    Set-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST' -filter "system.webServer/handlers" -name "." -value @{path = '*.php'; verb = 'GET,HEAD,POST'; modules = 'FastCgiModule'; scriptProcessor = 'C:\php\php-cgi.exe'; resourceType = 'Either'; requireAccess = 'Script' }

    # Create index.php file preconfigured with phpinfo()
    New-Item C:\inetpub\wwwroot\index.php
    Add-Content C:\inetpub\wwwroot\index.php "<?php phpinfo(); ?>"
}
end {
    # If a reboot is needed.
    if ($reboot.IsPresent) {
        Write-Host -f green "[INFO] Script complete in $($sw.Elapsed.Hours) hours, $($sw.Elapsed.Minutes) minutes, $($sw.Elapsed.Seconds) seconds."
        Write-Host ''
        Write-Warning "Server needs a reboot to complete configuration."
        Write-Warning "Please reboot server then open http://localhost/$($xml.info.iis.site_name)/index.php in Internet Explorer."
        Write-Warning "index.php should display PHP Info in Internet Explorer."
        Write-Host ''
        Break
    } else {
        Write-Host -f green "[INFO] Script complete in $($sw.Elapsed.Hours) hours, $($sw.Elapsed.Minutes) minutes, $($sw.Elapsed.Seconds) seconds."
        Write-Host ''
    }

    # Check PHP works
    Write-Host -f green "[INFO] Now opening Internet Explorer to check all works. You should see a PHP Info page."
    Start-Process "C:\Program Files\Internet Explorer\iexplore.exe" -ArgumentList "http://localhost/$($xml.info.iis.site_name)/index.php"
}