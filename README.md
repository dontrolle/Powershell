# Powershell

*A small toolbox of PowerShell functions.*

[![CI](https://github.com/dontrolle/Powershell/actions/workflows/ci.yml/badge.svg)](https://github.com/dontrolle/Powershell/actions/workflows/ci.yml)

A small collection of standalone PowerShell functions I've written and relied on across several machines over the years. Used together with my [powershell-profile](https://github.com/dontrolle/powershell-profile).

## Requirements

- PowerShell 5.1+ (Windows PowerShell or PowerShell 7)
- Windows only — `Out-Clip` relies on `System.Windows.Forms` for clipboard file-drop-list support.

## Installation

Import the module manifest to get every function and alias below in one go:

```powershell
Import-Module C:\path\to\Powershell\Powershell.psd1
```

Add that line to your `$PROFILE` to have them available in every session. Alternatively, dot-source a single script if you only want one function:

```powershell
. C:\path\to\Powershell\Update-File.ps1
```

## Contents

| Function                   | Alias  | Description                                                                                                                                   |
|-----------------------------|--------|------------------------------------------------------------------------------------------------------------------------------------------------|
| `Get-FileDefiningFunction`  | `gfdf` | Returns the file path that defines a given function.                                                                                             |
| `Update-File`               | `touch`| Creates a file, or updates its last-write-time if it already exists — like *nix `touch`. Supports `-WhatIf`/`-Confirm`.                          |
| `Out-Clip`                  | —      | Copies one or more files to the Windows clipboard as a real file-drop list, so they paste as files in Explorer — something `Set-Clipboard -Path` still can't do. |

### Examples

```powershell
# Find which file defines a function
gfdf Get-FileDefiningFunction

# Create a new file, or bump the last-write-time of an existing one
touch .\notes.txt

# Copy files to the clipboard so they can be pasted as files in Explorer
Get-ChildItem *.png | Out-Clip -Verbose
```

## Development

Run the tests ([Pester](https://pester.dev/) v5):

```powershell
Invoke-Pester -Path .\Tests
```

Run the linter ([PSScriptAnalyzer](https://github.com/PowerShell/PSScriptAnalyzer)):

```powershell
Invoke-ScriptAnalyzer -Path . -Recurse -Exclude Tests
```

Both run automatically on every push/PR via GitHub Actions — see [`.github/workflows/ci.yml`](.github/workflows/ci.yml).

## License

[MIT](LICENSE)
