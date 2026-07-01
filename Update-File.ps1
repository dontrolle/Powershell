<# 
.SYNOPSIS 
    Creates or updates the timestamp of a file at the given file-path, like the *nix touch shell command.
.PARAMETER File
    Path the file to be created or updated.
#>
Function Update-File
{
    [CmdletBinding(SupportsShouldProcess=$true)]
    Param(
        [Parameter(Mandatory=$true)]
        [string] $File)

    if(Test-Path $File)
    {
        if ($PSCmdlet.ShouldProcess($File, 'Update LastWriteTime'))
        {
            (Get-ChildItem $File).LastWriteTime = Get-Date
        }
    }
    elseif (Test-Path $File -IsValid)
    {
        if ($PSCmdlet.ShouldProcess($File, 'Create file'))
        {
            New-Item -ItemType File -Path $File -Force | Out-Null
        }
    }
    else {
        throw "The given file-path:'$File' is not a valid path"
    }
}

Set-Alias -Name touch -Value Update-File
