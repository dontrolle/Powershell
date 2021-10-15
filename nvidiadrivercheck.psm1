#Requires -Module AngleParse
# To get AngleParse - see https://github.com/kamome283/AngleParse

# Example usage:
# 
# $ProductType = "GeForce"
# $ProductSeries = "GeForce RTX 30 Series"
# $Product = "GeForce RTX 3080"
# $OperatingSystem = "Windows 10 64-bit"
# $DownloadType = "Game Ready Driver (GRD)"
# $Language = "English (US)"
# Import-Module -Name ".\nvidiadrivercheck.psm1" -ArgumentList "NVIDIA GeForce RTX 3080", $ProductType, $ProductSeries, $Product, $OperatingSystem, $DownloadType, $Language

param(

    # Supply the Devicename of your NVIDIA graphic card as reported by 
    #   Get-CimInstance win32_pnpSignedDriver | Select-Object Devicename
    [parameter(Position=0,Mandatory=$true)][string]$NvidiaDeviceName,

    # Supply the string-values for the all the options for your card in the dropdown
    # at https://www.nvidia.com/Download/index.aspx 
    [parameter(Position=1,Mandatory=$true)][string]$ProductType,
    [parameter(Position=2,Mandatory=$true)][string]$ProductSeries,
    [parameter(Position=3,Mandatory=$true)][string]$Product,
    [parameter(Position=4,Mandatory=$true)][string]$OperatingSystem,
    [parameter(Position=5,Mandatory=$true)][string]$DownloadType,
    [parameter(Position=6,Mandatory=$true)][string]$Language
)

function Get-SelectOptionValue() {
    param (
        # HTML to look for select in
        [Parameter(Mandatory)]
        [String]
        $Html,
        # HTML id of select
        [Parameter(Mandatory)]
        [String]
        $SelectId,
        # text value of select option to return value for
        [Parameter(Mandatory)]
        [String]
        $OptionText
    )

    return (($HTML | Select-HtmlContent "#$SelectId", ([AngleParse.Attr]::Element)).Options | Where-Object { $_.Text -eq $OptionText }).Value
}

function Get-ApiLookupValue(){
    param (
        [Parameter(Mandatory)]
        [String]
        $Page,
        [Parameter(Mandatory)]
        [String]
        $Name
    )

    return ($Page | Select-Xml -XPath "//LookupValue[Name='$Name']").Node.Value
}

$NvidiaDownloadPage = "https://www.nvidia.com/Download/index.aspx"
$NvidiaSearchDriverUrlFormatString = "https://www.nvidia.com/Download/processDriver.aspx?psid={0}&pfid={1}&rpf=1&osid={2}&lid={3}&lang=en-us&ctk=0&dtid={4}&dtcid=1"
$ApiLookupPage = "https://www.nvidia.com/Download/API/lookupValueSearch.aspx?TypeId={0}"

function Find-NvidiaDriverSearchPage()
{
    [OutputType([String])]
    Param()
    
    $ptPage = Invoke-WebRequest -Uri ($ApiLookupPage -f 1)
    $pt = Get-ApiLookupValue -Page $ptPage -Name $ProductType
    Write-Debug "Found value $pt for $ProductType"
    if(!$pt)
    {
        Throw "Found no value for $ProductType"
    }

    $psPage = Invoke-WebRequest -Uri ("$ApiLookupPage&ParentID=$pt" -f 2)
    $ps = Get-ApiLookupValue -Page $psPage -Name $ProductSeries
    Write-Debug "Found value $ps for $ProductSeries"
    if(!$ps)
    {
        Throw "Found no value for $ProductSeries"
    }    

    $pPage = Invoke-WebRequest -Uri ("$ApiLookupPage&ParentID=$ps" -f 3)
    $p = Get-ApiLookupValue -Page $pPage -Name $Product
    Write-Debug "Found value $p for $Product"
    if(!$p)
    {
        Throw "Found no value for $Product"
    }

    $osPage = Invoke-WebRequest -Uri ("$ApiLookupPage&ParentID=$ps" -f 4)
    $os = Get-ApiLookupValue -Page $osPage -Name $OperatingSystem
    Write-Debug "Found value $os for $OperatingSystem"
    if(!$os)
    {
        Throw "Found no value for $OperatingSystem"
    }

    $downloadPage = Invoke-WebRequest -Uri $NvidiaDownloadPage
    $dt = Get-SelectOptionValue -Html $downloadPage -SelectId "ddlDownloadTypeCrdGrd" -OptionText $DownloadType
    Write-Debug "Found value $dt for $DownloadType"
    if(!$dt)
    {
        Throw "Found no value for $DownloadType"
    }

    $lPage = Invoke-WebRequest -Uri ("$ApiLookupPage&ParentID=$ps" -f 5)
    $l = Get-ApiLookupValue -Page $lPage -Name $Language
    Write-Debug "Found value $l for $Language"
    if(!$l)
    {
        Throw "Found no value for $Language"
    }    

    $completeSearchString = $NvidiaSearchDriverUrlFormatString -f $ps,$p,$os,$dt,$l

    Write-Debug "Constructed NVIDIA driver search URI: $completeSearchString"

    return $completeSearchString
}

function Get-NvidiaInstalledVersion{
    [OutputType([int])]
    Param()

    $installedDriverVersion = (Get-CimInstance win32_pnpSignedDriver | Select-Object Devicename, driverversion | Where-Object { $_.devicename -like $NvidiaDeviceName }).driverversion;
    # results in smth like
    # 21.21.13.7557
    # now we pick out the last five digits, which match the ones reported by the driver-version in Windows
    $idvr = ($installedDriverVersion -replace "\.");
    $installedString = $idvr.Substring($idvr.Length - 5);
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

  WARNING - relies on undocumented APIs and screenscraping, FTW!

 .Description
  Checks local version of NVIDIA display driver version (for a graphics driver given as argument for the module)
  against the version available on NVIDIAs website (against a driver search URI given as argument for the module).

  If a possible new version is found, by default the download URL for the drivers are copied to the 
  clipboard for manual download and installation. If the -Download switch is given, the drivers are downloaded 
  directly to your Downloads folder.

  WARNING - relies on undocumented APIs and screenscraping, FTW!

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

    $driverSearchPage = Find-NvidiaDriverSearchPage
    
    $driverPage = (Invoke-WebRequest -Uri $driverSearchPage).Content
  
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