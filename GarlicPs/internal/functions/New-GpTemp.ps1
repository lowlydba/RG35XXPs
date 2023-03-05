function New-GpTemp {

    [CmdletBinding()]
    param (
        [Parameter (Mandatory = $true)]
        [string]$TempPath,
        [Parameter (Mandatory = $false)]
        [bool]$ClearTempPath = $false,
        [Parameter (Mandatory = $true)]
        [string]$GarlicPath
    )
    process {
        if ((Test-Path -Path $TempPath) -and (Get-ChildItem -Path $TempPath)) {
            if ($ClearTempPath -eq $true) {
                Write-Verbose -Message "Clearing existing temp dir '$TempPath'"
                Remove-Item -Path $TempPath -Recurse -Force -Confirm:$false
                New-Item -Path $GarlicPath -ItemType Directory | Out-Null
            }
        }
        else {
            Write-Verbose -Message "Creating $TempPath"
            if (!(Test-Path -Path $TempPath)) {
                New-Item -Path $TempPath -ItemType Directory | Out-Null
            }
            if (!(Test-Path -Path $GarlicPath)) {
                New-Item -Path $GarlicPath -ItemType Directory | Out-Null
            }
        }
    }
}
