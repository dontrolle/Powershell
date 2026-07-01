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
.EXAMPLE 
    dir *somepattern* | Out-Clip
.EXAMPLE 
    Out-Clip somefile -Verbose
.EXAMPLE 
    dir *somepattern* | Out-Clip somefile -Verbose
.NOTES
    Author     : Troels Damgaard
#>
function Out-Clip
{
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
        [Alias("FullName")]
        [string[]]$Paths)

    begin {
        $filePaths = @()
    }

    process {
        foreach ($path in $Paths) {
            $fullPath = Resolve-Path $path

            Write-Verbose "Adding $fullPath ..."
            $filePaths += $fullPath
        }
    }

    end {
        $funcAdd =
        {
            function AddToClipboard($filePaths)
            {
                Add-Type -Assembly System.Windows.Forms

                $pathsCol = New-Object -typeName System.Collections.Specialized.StringCollection

                foreach ($path in $filePaths) {
                    [void]$pathsCol.Add($path)
                }
                $filesNo = $pathsCol.Count

                if($filesNo -gt 0)
                {
                    [Windows.Forms.Clipboard]::SetFileDropList($pathsCol)
                }
                Write-Information "$filesNo files added to clipboard." -InformationAction Continue
            }

            if ($args.Count -eq 0) {
                $fileArgs = @($input)
            }
            else {
                $fileArgs = $args
            }

            AddToClipboard($fileArgs)
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
}

