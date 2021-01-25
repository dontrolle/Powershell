<# 
.SYNOPSIS 
    Given the name of a PowerShell function, returns the file location of its defining scriptblock.
    Returns empty if the name does not match a known PowerShell function defined within a scriptblock.
.PARAMETER FunctionName
    The name of a PowerShell function.
#>
function Get-FileDefiningFunction()
{
    Param(
        [Parameter(Mandatory=$true)]
        [string] $FunctionName)

    (Get-Command $FunctionName).ScriptBlock.File
}

Set-Alias -name gfdf -value Get-FileDefiningFunction