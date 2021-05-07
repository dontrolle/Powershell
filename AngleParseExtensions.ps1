#Requires -Module AngleParse

<#
.SYNOPSIS
    Given HTML, the id of a select and the text in said option, returns the value of the found select option.

.DESCRIPTION
    Given a HTML page, the id of a select and the text in said option, returns the value of the found select option.

.EXAMPLE
    Get-SelectOptionValue -Html $somehtml -SelectId "someid" -OptionText "My select text"

.NOTES
    Requires PS module AngleParse, see https://github.com/kamome283/AngleParse.
#>
function Get-SelectOptionValue() {
    param (
        # HTML to look for select in
        [Parameter(Mandatory)]
        [String]
        $Html,
        # HTML id of select
        [Parameter(Mandatory)]
        [String]
        $SelectId,
        # text value of select option to return value for
        [Parameter(Mandatory)]
        [String]
        $OptionText
    )

    return (($HTML | Select-HtmlContent "#$SelectId", ([AngleParse.Attr]::Element)).Options | Where-Object { $_.Text -eq "GeForce" }).Value
}