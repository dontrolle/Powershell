$NvidiaDriverSearchString = "*nvidia Geforce GTX 970*"

$NvidiaDriverWebsite = "http://www.nvidia.com/Download/processDriver.aspx?psid=98&pfid=756&rpf=1&osid=57&lid=1&lang=en-us&ctk=0"

function Find-NvidiaDriverPage()
{
    [OutputType([String])]
    Param()

    $ns = Invoke-WebRequest -Uri $NvidiaDriverWebsite 
    return $ns.ParsedHtml.body.innerText

# actual download button link
#    http://www.nvidia.com/content/DriverDownload-March2009/confirmation.php?url=/Windows/375.70/375.70-desktop-win10-64bit-international-whql.exe&lang=us&type=GeForce

# actual download link
#    http://us.download.nvidia.com/Windows/375.70/375.70-desktop-win10-64bit-international-whql.exe
}

function Get-NvidiaInstalledVersion{
    [OutputType([int])]
    Param()

    $installedDriverVersion = (Get-WmiObject Win32_PnPSignedDriver| select devicename, driverversion | where {$_.devicename -like $NvidiaDriverSearchString}).driverversion;
    # results in smth like
    # 21.21.13.7557
    $installedString = ($installedDriverVersion -replace "\.").Substring(5,5);
    $installed = $installedString -as [int]
    if($installed -is [int]){
        return $installed
    }

    $Error = New-Object System.InvalidOperationException "Driver version parsing failed; best effort found '$installedString', which could not be parsed as a version number."
    Throw $Error
}

function Get-NvidiaAvailableVersion{
    [OutputType([int])]
    Param ([string] $driverPage)

    $page = Invoke-WebRequest $driverPage
    # results in smth like
    # 375.57&nbsp;&nbsp;<B><SUP>WHQL</SUP></B>
    $avaitrimmed = ($page.ParsedHtml.GetElementById("tdVersion").firstChild().data -replace "\.").Trim()
    $available = $avaitrimmed -as [int]
    if($available -is [int]){
        return $available
    }

    $Error = New-Object System.InvalidOperationException "Screen-scraping for available version failed. Best effort found '$avaitrimmed', which could not be parsed as a version-number."
    Throw $Error
}

<# 
 .Synopsis
  Checks local version of NVIDIA display driver version (for a hardcoded graphics driver)
  against the version available on NVIDIAs website (against a hardcoded URI).

  Beware - screenscraping, FTW.

 .Description
  Checks local version of NVIDIA display driver version (for a hardcoded graphics driver)
  against the version available on NVIDIAs website (against a hardcoded URI).

  If a possible new version is found, the download uri is printed and copied to the 
  clipboard for manual download and installation.

  Beware - screenscraping, FTW.

 .Example
   # Check driver version with minimal output.
   Test-NvidiaDriver

 .Example
   # Check driver version with debug output.
   Test-NvidiaDriver -Debug
#>
function Test-NvidiaDriver{
    [cmdletbinding()]
    Param()

    $driverPage = Find-NvidiaDriverPage
  
    $avai = Get-NvidiaAvailableVersion -driverPage $driverPage
    Write-Debug "Found available version: $avai"

    $inst = Get-NvidiaInstalledVersion
    Write-Debug "Found install version: $inst"

    if($avai -gt $inst){
        Write-Host "It looks like there's a more recent driver available at $driverPage"
        Set-Clipboard $driverPage
        Write-Host "Download url copied to clipboard; paste in browser to download."        
    }
    else {
        Write-Host "It looks like your drivers are up-to-date."
    }
}

Export-ModuleMember -function Test-NvidiaDriver