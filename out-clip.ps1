<# 
.SYNOPSIS 
    Copies files to the Windows clipboard.
    The best replacement for Clippy!
.DESCRIPTION 
    Given files from the pipeline or as a parameter, copies one or 
    more files to the Windows clipboard.
    Use -Verbose to echo files copied.
.PARAMETER Paths
    One or more file paths.
.PARAMETER Verbose
    If given, full paths for all files are echoed to the console.
.EXAMPLE 
    dir *somepattern* | Out-Clip
.EXAMPLE 
    Out-Clip somefile -verbose
.EXAMPLE 
    dir *somepattern* | Out-Clip somefile -verbose
.NOTES
    Author     : Troels Damgaard (Edlunds A/S)
#>
function Out-Clip
{
    param([string[]]$Paths, [switch]$Verbose)
    
    $rawPaths = @($input)
    if($null -ne $Paths) {
        $rawPaths = $rawPaths + $Paths
    }

    $filePaths = @()
    
    foreach ($path in $rawPaths) {
        $fullPath = Resolve-Path $path
   
        if ($Verbose.IsPresent) {
            Write-Host "Adding $fullPath ..."
        }
        $filePaths += $fullPath
    }
    
    $funcAdd = 
    {
        function AddToClipboard($filePaths)
        {
            Add-Type -Assembly System.Windows.Forms

            $pathsCol = New-Object -typeName System.Collections.Specialized.StringCollection

            foreach ($path in $filePaths) {
                $ignore = $pathsCol.Add($path)
            }
            $filesNo = $pathsCol.Count

            if($filesNo -gt 0)
            {
                [Windows.Forms.Clipboard]::SetFileDropList($pathsCol)
            }
            Write-Host "$filesNo files added to clipboard."
        }
        
        if ($args.Count -eq 0) {
            $args = @($input)
        }
        
        AddToClipboard($args)
    }

    $isMTA = [Threading.Thread]::CurrentThread.ApartmentState.ToString() -eq 'MTA'
    if($isMTA)
    {
        $filePaths | Powershell -NoProfile -STA -Command $funcAdd
    }
    else
    {
        Invoke-Command $funcAdd -ArgumentList $filePaths
    }
}
