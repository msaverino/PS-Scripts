<#

    .SYNOPSIS
    Gets the Edge Version.

    .DESCRIPTION
    Gets the version of Microsoft Edge on a remote computer or local computer.

    .PARAMETER ComputerName
    Specified a remote machine to run the function against. This parameter defaults to the local machine.

    .EXAMPLE
    Get-EdgeVersion

    Gets the Edge version of the local machine.

    .EXAMPLE
    Get-EdgeVersion -ComputerName "WKS01"

    Gets the Edge version of the remote machine WKS01.

#>

function Get-EdgeVersion {
    [CmdletBinding()]
    param (
        # Remote Computer Name
        [Parameter(Mandatory=$false, ValueFromPipeline=$true)]
        [Alias('RemoteComputer', 'Computer')]
        [string]
        $ComputerName = $env:COMPUTERNAME
    )

    begin {
        $localAddress = @("127.0.0.1", "localhost", ".", "$($env:COMPUTERNAME)")
        $scriptBlock = [scriptblock]{
            $edgeExe = Get-ItemPropertyValue "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\msedge.exe" "(default)"
            return (Get-Item $edgeExe).VersionInfo.ProductVersion
        }
    }
    
    process {
        if ($localAddress -contains $ComputerName){
            $edgeExe = Get-ItemPropertyValue "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\msedge.exe" "(default)"
            (Get-Item $edgeExe).VersionInfo.ProductVersion
        } else {
            try {
                Invoke-Command -ComputerName $ComputerName -ScriptBlock $scriptBlock -ErrorAction Stop
            } catch {
                Write-Error -Message "Could not connect to computer '$ComputerName'."
            }
        }
    }
}
