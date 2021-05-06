#Requires -Module AngleParse
# To get AngleParse - see https://github.com/kamome283/AngleParse

param(

    # Supply the Devicename of your NVidia graphic card as reported by 
    #   Get-CimInstance win32_pnpSignedDriver | Select-Object Devicename
    [parameter(Position=0,Mandatory=$true)][string]$NvidiaDeviceName,
    
    # Supply the page that the https://www.nvidia.com/Download/index.aspx site searches for drivers for the 
    # NVidia graphic card that you are checking for.
    # Looks something like https://www.nvidia.com/Download/processDriver.aspx?psid=...&pfid=...&rpf=..&osid=..&lid=..&lang=en-us&ctk=..&dtid=..&dtcid=..
    [parameter(Position=1,Mandatory=$true)][string]$NvidiaDriverUrl
)


function Find-NvidiaDriverPage()
{
    [OutputType([String])]
    Param()

    $ns = Invoke-WebRequest -Uri $NvidiaDriverUrl
    return $ns.Content
}

function Get-NvidiaInstalledVersion{
    [OutputType([int])]
    Param()

    $installedDriverVersion = (Get-CimInstance win32_pnpSignedDriver | Select-Object Devicename, driverversion | Where-Object { $_.devicename -like $NvidiaDeviceName }).driverversion;
    # results in smth like
    # 21.21.13.7557
    # now we pick out the last five digits, which match the ones reported by the driver-version in Windows
    $installedString = ($installedDriverVersion -replace "\.").Substring(5,5);
    $installed = $installedString -as [int]
    if($installed -is [int]){
        return $installed
    }

    $ErrorMessage = New-Object System.InvalidOperationException "Driver version parsing failed; best effort found '$installedString', which could not be parsed as a version number."
    Throw $ErrorMessage
}

function Get-NvidiaAvailableVersion{
    [OutputType([int])]
    Param ([string] $driverPage)

    $page = Invoke-WebRequest $driverPage
    # following results in smth like
    # 375.57&nbsp;&nbsp;<B><SUP>WHQL</SUP></B>
    $avaitrimmed = ($page | Select-HtmlContent "#tdVersion").trim()
    # now we pick the five digits
    $avainumber = ($avaitrimmed -replace "\.").substring(0,5)
    $available = $avainumber -as [int]
    if($available -is [int]){
        return $available
    }

    $ErrorMessage = New-Object System.InvalidOperationException "Screen-scraping for available version failed. Best effort found '$avaitrimmed', which could not be parsed as a version-number."
    Throw $ErrorMessage
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