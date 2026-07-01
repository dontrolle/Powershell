# Root module: dot-sources every standalone function script in this repo so they
# can be discovered and imported together via Import-Module .\Powershell.psd1

$scripts = @(
    'Get-FileDefiningFunction.ps1'
    'Update-File.ps1'
    'out-clip.ps1'
)

foreach ($script in $scripts) {
    . (Join-Path $PSScriptRoot $script)
}

Export-ModuleMember -Function 'Get-FileDefiningFunction', 'Update-File', 'Out-Clip' -Alias 'gfdf', 'touch'
