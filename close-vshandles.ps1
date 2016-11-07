<# 
.SYNOPSIS 
    Closes any open handles to xml-files held by Visual Studio in the build output directory 
    (i.e., bin\Debug or bin\Release).
    Note: Requires admin privileges and that SysInternals handle.exe is in path.
.PARAMETER Path
    Path to the root of the Visual Studio project-directory to close xml-handles for.
.PARAMETER Release
    If set, look for open handles to xml-files in bin\Release; else look in bin\Debug.
.PARAMETER Force
    If set, found handles will be closed without asking for confirmation.
#>
function Close-VsXmlHandles {
  [cmdletbinding()]
  param([string] $Path, [switch]$Release = $false, [switch]$Force = $false)

  # NOTE It'd be nice to let this self-elevate

  $Path = "$Path\bin\Debug"
  if($Release){
    $Path = "$Path\bin\Release"
  }

  # Requires elevation
  $lines = handle -p devenv.exe $path | ? { $_.StartsWith("devenv.exe") -and $_.EndsWith(".xml") }
  if(!$lines){
    Write-Host "No matching handles found."
    return
  }

  Write-Verbose "Found these matching handles:" 
  Write-Verbose $lines

  foreach ($line in $lines) {
    # parse and find pid for devenv.exe process and handle for file (hex)
    $p_part = $line | Select-String -pattern "pid: ([0-9]*)"
    $p = $p_part.matches.Groups[1].Value
  
    $h_part = $line | Select-String "type: File\s*([0-9ABCDEF]*): "
    $h = $h_part.matches.Groups[1].Value

    Write-Verbose "Closing handle $h for process with pid $p (devenv.exe)"
    
    $y = ""
    if($force){
      $y = "-y"
    }

    # Requires elevation
    handle -p $p -c $h $y
  }
}
