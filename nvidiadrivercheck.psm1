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

    $ns = (Invoke-WebRequest -Uri $NvidiaDriverUrl).Content

    Write-Debug "Found driver page at: $ns"

    return $ns
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

function Get-DirectDownloadLink{
    [OutputType([string])]
    Param ([string] $driverDownloadPage)

    Write-Debug "Accessing $driverDownloadPage to get link to confirmation page"
    $downloadPage = Invoke-WebRequest $driverDownloadPage

    #get confirmation page link
    $confirmationUrl = "https://www.nvidia.com/" + ($downloadPage | Select-HtmlContent "#lnkDwnldBtn", ([AngleParse.Attr]::Href))
    Write-Debug "Found URL for confirmation page: $confirmationUrl"

    $confirmationPage = Invoke-WebRequest $confirmationUrl

    $href = $confirmationPage | Select-HtmlContent "#mainContent > table > tbody > tr > td > a", ([AngleParse.Attr]::Href)
    $fixupHref = "https:$href"

    Write-Debug "Found URL for drivers at: $fixupHref"
    return $fixupHref
}

function Get-Driver{
    [OutputType([string])]
    param (
        [Parameter(Mandatory=$true)]
        [string]
        $DownloadUrl,
        [Parameter(Mandatory=$true)]
        [string]
        $DownloadDirectory
    )

    $filename = $downloadUrl.Split("/")[-1]
    $downloadPath = Join-Path -Path $downloadDirectory -ChildPath $filename

    Start-BitsTransfer $downloadUrl $downloadPath

    return $downloadPath
}

<# 
 .Synopsis
  Checks local version of NVIDIA display driver version (for a graphics driver given as argument for the module)
  against the version available on NVIDIAs website (against a driver search URI given as argument for the module).

  Beware - screenscraping, FTW.

 .Description
  Checks local version of NVIDIA display driver version (for a graphics driver given as argument for the module)
  against the version available on NVIDIAs website (against a driver search URI given as argument for the module).

  If a possible new version is found, by default the download URL for the drivers are copied to the 
  clipboard for manual download and installation. If the -Download switch is given, the drivers are downloaded 
  directly to your Downloads folder.

  Beware - screenscraping, FTW.

 .Example
    Test-NvidiaDriver

    Checks driver version with minimal output. If new drivers are found, the download URL for the drivers are copied to the 
  clipboard for manual download and installation.
   

 .Example
    Test-NvidiaDriver -Debug
 
    Checks driver version with debug output. If new drivers are found, the download URL for the drivers are copied to the 
  clipboard for manual download and installation.
   

 .Example
    Test-NvidiaDriver -Download

    Checks driver version and downloads drivers to Downloads folder, if new are found.
#>
function Test-NvidiaDriver{
    [CmdletBinding()]
    param (
        # If given, downloads the drivers directly to your Downloads folder
        [Parameter()]
        [Switch]
        $Download = $false
    )

    $driverPage = Find-NvidiaDriverPage
  
    $avai = Get-NvidiaAvailableVersion -driverPage $driverPage
    Write-Debug "Found available version: $avai"

    $inst = Get-NvidiaInstalledVersion
    Write-Debug "Found install version: $inst"

    if($avai -gt $inst){
        Write-Host "It looks like there's a more recent driver available."
        $driverDownloadUrl = Get-DirectDownloadLink $driverPage
        if($Download){
            $downloadsDirectory = (New-Object -ComObject Shell.Application).NameSpace('shell:Downloads').Self.Path            
            Write-Host "Downloading to your Downloads folder at $downloadsDirectory"
            $downloadPath = Get-Driver -DownloadUrl $driverDownloadUrl -DownloadDirectory $downloadsDirectory
            Write-Host "File downloaded to $downloadPath"
        }
        else{
            Set-Clipboard $driverDownloadUrl
            Write-Host "Download url copied to clipboard; enter in browser to download manually."
        }
    }
    else {
        Write-Host "It looks like your drivers are up-to-date."
    }
}

Export-ModuleMember -function Test-NvidiaDriver