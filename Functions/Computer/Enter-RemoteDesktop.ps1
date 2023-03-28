<#
	.SYNOPSIS
		Enters a Remote Desktop Session
	
	.DESCRIPTION
		A detailed description of the Enter-RemoteDesktop function.
	
	.PARAMETER Width
		Specifies the width of the RDP window in pixels. The default value is 1366 pixels.
	
	.PARAMETER Height
		Specifies the height of the RDP window in pixels. The default value is 768 pixels.
	
	.PARAMETER FullScreen
		Specifies whether to enter full screen mode.
	
	.PARAMETER ComputerName
		Specifies the name of the remote computer to connect to.
	
	.EXAMPLE
		PS C:\> Enter-RemoteDesktop -ComputerName "WKS01"

		This example will connect to the remote computer "WKS01" with the display of 1366x768.

    .EXAMPLE
		PS C:\> Enter-RemoteDesktop -ComputerName "WKS01" -FullScreen

		This example will connect to the remote computer "WKS01" in full screen.

    .EXAMPLE
		PS C:\> Enter-RemoteDesktop -ComputerName "WKS01" -Width 1920 -Height 1080

		This example will connect to the remote computer "WKS01" in with the display of 1920x1080.
#>
function Enter-RemoteDesktop
{
	[CmdletBinding(DefaultParameterSetName = 'WH')]
	param
	(
		[Parameter(ParameterSetName = 'WH',
				   Mandatory=$false,
				   Position = 2)]
		[int]$Width = 1366,
		[Parameter(ParameterSetName = 'WH',
				   Mandatory=$false,
				   Position = 3)]
		[int]$Height = 768,
		[Parameter(ParameterSetName = 'FullScreen',
				   Position = 2)]
		[switch]$FullScreen,
		[Parameter(Mandatory = $true,
				   Position = 1)]
		[Alias('RemoteComputer', 'Computer')]
		[string]$ComputerName
	)
	
	switch ($PsCmdlet.ParameterSetName)
	{
		'WH' {
            # Defines the Width and Height
			$spArguments = "/v:$ComputerName /w:$Width /h:$Height"
			break
		}
		'FullScreen' {
            # Defines Full Screen
			$spArguments = "/v:$ComputerName /f"
			break
		}
	}
	
	Start-Process -FilePath "mstsc" -ArgumentList $spArguments
}
