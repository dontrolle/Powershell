BeforeAll {
    . (Join-Path $PSScriptRoot '..\Get-FileDefiningFunction.ps1')
}

Describe 'Get-FileDefiningFunction' {
    It 'returns the file path that defines a known function' {
        $path = Get-FileDefiningFunction -FunctionName 'Get-FileDefiningFunction'
        $path | Should -Be (Resolve-Path (Join-Path $PSScriptRoot '..\Get-FileDefiningFunction.ps1')).Path
    }

    It 'accepts the function name from the pipeline' {
        $path = 'Get-FileDefiningFunction' | Get-FileDefiningFunction
        $path | Should -Be (Resolve-Path (Join-Path $PSScriptRoot '..\Get-FileDefiningFunction.ps1')).Path
    }

    It 'returns nothing for an unknown function name' {
        $path = Get-FileDefiningFunction -FunctionName 'Some-FunctionThatDoesNotExist' -ErrorAction SilentlyContinue
        $path | Should -BeNullOrEmpty
    }

    It 'registers the gfdf alias' {
        (Get-Alias -Name 'gfdf').Definition | Should -Be 'Get-FileDefiningFunction'
    }
}
