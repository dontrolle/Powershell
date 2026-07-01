BeforeAll {
    . (Join-Path $PSScriptRoot '..\Update-File.ps1')
}

Describe 'Update-File' {
    BeforeEach {
        $script:testDir = Join-Path ([System.IO.Path]::GetTempPath()) ([guid]::NewGuid())
        New-Item -ItemType Directory -Path $testDir -Force | Out-Null
    }

    AfterEach {
        Remove-Item -Path $testDir -Recurse -Force -ErrorAction SilentlyContinue
    }

    It 'creates a new file when it does not exist' {
        $file = Join-Path $testDir 'newfile.txt'
        Test-Path $file | Should -BeFalse

        Update-File -File $file

        Test-Path $file | Should -BeTrue
    }

    It 'updates the LastWriteTime of an existing file' {
        $file = Join-Path $testDir 'existing.txt'
        Set-Content -Path $file -Value 'hello'
        $oldTime = (Get-Date).AddDays(-1)
        (Get-Item $file).LastWriteTime = $oldTime

        Update-File -File $file

        (Get-Item $file).LastWriteTime | Should -BeGreaterThan $oldTime
    }

    It 'throws for an invalid path' {
        { Update-File -File "$([char]0)invalid" } | Should -Throw
    }

    It 'registers the touch alias' {
        (Get-Alias -Name 'touch').Definition | Should -Be 'Update-File'
    }
}
