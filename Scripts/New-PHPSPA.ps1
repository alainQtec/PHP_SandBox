function New-PHPSPA {
    <#
    .SYNOPSIS
        Creates a PHP single page app starter template.
    .DESCRIPTION
        A custom function to create a single page app in PHP
    .EXAMPLE
        New-PHPSPA -Name "webapp1" -Verbose
        Explanation of the function or its result. You can include multiple examples with additional .EXAMPLE lines
    .NOTES
        This is meant to be used when creating a starter template app.
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    [OutputType([PHPSPA])]
    param (
        # The name of your app
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [alias('AppName')]
        [string]$name,

        # Ex: about for about.php, conatct for contact.php ...
        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [alias('Pages')]
        [string[]]$pageNames,

        # The folder in which to save the code
        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string]$OutPath = $PSScriptRoot,

        [Parameter(Mandatory = $false)]
        [switch]$StartDEVserver
    )


    begin {
        class PHPSPA {
            [ValidateNotNullOrEmpty()][string]$name
            [ValidateNotNullOrEmpty()][IO.DirectoryInfo]$path
            hidden [ValidateNotNullOrEmpty()][IO.FileInfo]$instantclickmjs
            hidden [ValidateNotNullOrEmpty()][uri]$instantclickUrl = [uri]::new("http://instantclick.io/v3.1.0/instantclick.min.js")
            hidden [ValidateNotNullOrEmpty()][string]$title = 'My Single Page App'
            hidden [bool]$HasDarkMode

            PHPSPA([string]$name, [string]$path) {
                if ([IO.DirectoryInfo]::New($path).Attributes -ne 'Directory') {
                    throw [System.Management.Automation.ValidationMetadataException]::new("Please provide a valid Directory path.")
                }
                $this.name = $name
                $this.path = [IO.DirectoryInfo]::New([IO.Path]::Combine($path, $name))
                $this.instantclickmjs = [IO.FileInfo]::New([IO.Path]::Combine($this.path.FullName, "instantclick.min.js"));
            }
            [void] bootstrap() { $this.bootstrap($null) } # will create only default pages
            [void] bootstrap([string[]]$Pages) { $this.bootstrap($Pages, $false) }
            [void] bootstrap([string[]]$Pages, [string]$Force) {
                if ($this.path.Exists) {
                    if (!$force) {
                        throw [System.InvalidOperationException]::New("'$($this.path.FullName)' already exists!")
                    }
                    Remove-Item -Path $this.path -Recurse -Force -ErrorAction Stop
                }
                $this.path = New-Item -Path $this.path.FullName -ItemType Directory -ErrorAction Stop
                if (!$this.instantclickmjs.Exists) {
                    Invoke-WebRequest -Uri $this.instantclickUrl -OutFile $this.instantclickmjs.FullName -Verbose:$false
                }
                $defaults = 'index', 'about', 'footer', 'header', 'utils'
                $Names = $defaults
                if ($null -ne $Pages) {
                    $Names = $pages.ForEach({ if ($_.EndsWith('.php')) { $_.TrimEnd([char[]]".php" ) }else { $_ } })
                }
                $Names = $Names.Where({ $_ -notin $defaults })
                foreach ($name in $defaults) {
                    $strb = [System.Text.StringBuilder]::New()
                    switch ($name) {
                        'index' {
                            $strb.AppendLine("
                                <?php
                                require_once 'utils.php';
                                echo head('Home', 'index');
                                ?>
                                <div class='content' id='content'>
                                    <button id='sidebarCollapse' class='toggle-btn'>[=]</button>
                                    <header>
                                        <h1>HomePage Header</h1>
                                    </header>
                                    <p>Homepage welcome message</p>
                                    <p>This is the content area of the home page.</p>
                                </div>
                                <?php
                                echo footer();"
                            )
                            [IO.File]::WriteAllLines(
                                [IO.Path]::Combine($this.path.FullName, 'index.php'),
                                $strb.ToString().Split("`r").ForEach({ if ($_.Length -gt 32) { $_.Substring(33) } }), [System.Text.Encoding]::UTF8
                            )
                            break;
                        }
                        'about' {
                            $strb.AppendLine("
                                <?php
                                require_once 'utils.php';
                                echo head('Home', 'about');
                                ?>
                                <div class='content' id='content'>
                                    <button id='sidebarCollapse' class='toggle-btn'>[=]</button>
                                    <h1>About!</h1>
                                    <p>This is the about page</p>
                                </div>
                                <?php
                                echo footer();"
                            )
                            [IO.File]::WriteAllLines(
                                [IO.Path]::Combine($this.path.FullName, 'about.php'),
                                $strb.ToString().Split("`r").ForEach({ if ($_.Length -gt 32) { $_.Substring(33) } }), [System.Text.Encoding]::UTF8
                            )
                            break;
                        }
                        'footer' {
                            [void]$strb.AppendLine("
                                <footer>
                                    <p>Acme Inc</p>
                                </footer>"
                            )
                            [IO.File]::WriteAllLines(
                                [IO.Path]::Combine($this.path.FullName, 'footer.php'),
                                $strb.ToString().Split("`r").ForEach({ if ($_.Length -gt 32) { $_.Substring(33) } }), [System.Text.Encoding]::UTF8
                            )
                            break;
                        }
                        'utils' {
                            [void]$strb.AppendLine("
                                <?php
                                function head(`$title, `$activepage) {
                                    ob_start();
                                ?>
                                <!DOCTYPE html>
                                <html lang='en'>
                                <head>
                                    <meta charset='UTF-8'>
                                    <meta http-equiv='X-UA-Compatible' content='IE=edge'>
                                    <meta name='viewport' content='width=device-width, initial-scale=1.0'>
                                    <title><?= `$title; ?></title>
                                    <style>
                                        body {
                                            margin: 0;
                                            padding: 0;
                                            font-family: Arial, sans-serif;
                                            min-height: 100vh;
                                            overflow-x: hidden;
                                        }

                                        .navbar {
                                            padding: 1rem;
                                            background-color: #f2f2f2;
                                            min-width: 16rem;
                                            width: 16rem;
                                            height: 100vh;
                                            position: fixed;
                                            top: 0;
                                            left: 0;
                                            box-shadow: 3px 3px 1rem rgba(0, 0, 0, 0.1);
                                            transition: all 0.4s;
                                        }

                                        .navbar a {
                                            display: block;
                                            padding: 1rem;
                                            margin-bottom: 1rem;
                                            background-color: #fff;
                                            color: #333;
                                            text-decoration: none;
                                            border-radius: 5px;
                                        }

                                        .navbar a:hover {
                                            background-color: #ddd;
                                        }

                                        .content {
                                            width: calc(100% - 18rem);
                                            margin-left: 18rem;
                                            transition: all 0.4s;
                                        }

                                        h1 {
                                            font-size: 2em;
                                            margin-top: 0;
                                        }

                                        .item {
                                            text-decoration: none;
                                            color: #504f4f;
                                        }

                                        .item:hover {
                                            background: #e7e7e7;
                                        }

                                        .item.active {
                                            background: #d9e8ff;
                                            color: #1f57dd;
                                        }

                                        .item.active:hover {
                                            background: #c7ddff;
                                        }

                                        #sidebar.active {
                                            margin-left: -18rem;
                                        }

                                        #content.active {
                                            width: 100%;
                                            margin-left: 1.5rem;
                                        }

                                        @media (max-width: 767px) {
                                            #sidebar {
                                                margin-left: -18rem;
                                            }

                                            #sidebar.active {
                                                padding: .4rem;
                                                margin-left: 0;
                                            }

                                            #content {
                                                width: 100%;
                                                margin: .5rem;
                                            }

                                            #content.active {
                                                margin-left: 17rem;
                                                width: calc(100% - 17rem);
                                            }
                                        }

                                        .toggle-btn {
                                            display: block;
                                            position: relative;
                                            background-color: #fff;
                                            margin: .5rem;
                                            padding: 1rem;
                                            border: none;
                                            border-radius: 5px;
                                            box-shadow: 0 0 5px rgba(0, 0, 0, 0.2);
                                            cursor: pointer;
                                        }

                                        .toggle-btn i {
                                            font-size: 1.2em;
                                        }
                                    </style>
                                </head>

                                <body>
                                    <?php
                                        `$pages = array('Home', 'About', 'Contact');
                                        echo `"<div class='navbar' id='sidebar'>`";
                                        foreach (`$pages as `$page) {
                                            `$href = `$page . '.php';
                                            `$name = `$page; `$class = 'item';
                                                if (`$page == `$activepage) {
                                                `$class = 'item active';
                                            }
                                            if (`$page == 'Home') {
                                                `$href = 'index.php';
                                            }
                                            echo `"<a href='`$href' class='`$class'>`$name</a>`";
                                        }
                                        echo '</div>';
                                        return ob_get_clean();
                                    }

                                    function footer()
                                    {
                                        ob_start(); ?>
                                        <script src='https://cdnjs.cloudflare.com/ajax/libs/jquery/3.6.0/jquery.min.js'></script>
                                        <script>
                                            `$(function () {
                                                `$('#sidebarCollapse').on('click', function () {
                                                    `$('#sidebar, #content').toggleClass('active');
                                                });
                                            });
                                        </script>
                                        <script src='instantclick.min.js'></script>
                                        <script data-no-instant>
                                            InstantClick.init();
                                        </script>
                                    </body>
                                </html>
                                <?php
                                    return ob_get_clean();
                                }"
                            )
                            [IO.File]::WriteAllLines(
                                [IO.Path]::Combine($this.path.FullName, 'utils.php'),
                                $strb.ToString().Split("`r").ForEach({ if ($_.Length -gt 32) { $_.Substring(33) } }),
                                [System.Text.Encoding]::UTF8
                            )
                            break;
                        }
                        Default {}
                    }
                }
                if ($Names.count -gt 0) {
                    $Names.ForEach({ $this.CreatePage($_) })
                }
            }
            [void] StartDEVserver() {
                trap {
                    Write-Verbose "Closing devServer ..." -Verbose
                    Pop-Location
                }
                Push-Location $this.path.FullName
                php -S localhost:4000
            }
            hidden [void] CreatePage([string]$name) {
                Write-Debug "Creating Page $name ..." -Debug
            }
        }
    }

    process {
        try {
            $app = [PHPSPA]::new($name, $OutPath)
            if ($PSCmdlet.ShouldProcess($app.path.FullName, "Boostrapp")) {
                $app.bootstrap($pageNames);
            }
            if ($StartDEVserver.IsPresent) { $app.StartDEVserver() }
        } catch {
            Write-Error $_
            # $PSCmdlet.ThrowTerminatingError()
        }
    }

    end {
        if ($app.path.Exists) {
            Write-Host "Single page app $name was created successfully!" -ForegroundColor Green
        }
        return $app
    }
};