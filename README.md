# Powershell

Collection of various PowerShell functions and modules, that I've developed and found to be generally useful across several machines over the years.

Some modules may have dependencies - please refer to the `#Requires` statement in each module.

## Contents

- `Get-FileDefiningFunction.ps1` (alias `gfdf`) - returns the file that defines a given function.
- `Update-File.ps1` (alias `touch`) - creates a file or updates its last-write-time, like *nix `touch`.
- `out-clip.ps1` (`Out-Clip`) - copies files to the Windows clipboard as a real file-drop list (pastable in Explorer), which `Set-Clipboard -Path` still can't do natively.

All three are exported together via the `Powershell.psd1` module manifest:

```powershell
Import-Module .\Powershell.psd1
```

## Tests

Unit tests live under `Tests\` and use [Pester](https://pester.dev/) v5:

```powershell
Invoke-Pester -Path .\Tests
```
