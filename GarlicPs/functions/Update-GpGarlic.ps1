function Update-GpGarlic {

	[CmdletBinding()]
	param (
		[Parameter (Mandatory = $false)]
		[string]$LocalFile,
		[Parameter (Mandatory = $false)]
		[string]$TempPath = (Join-Path -Path ([System.IO.Path]::GetTempPath()) "\GarlicPs"),
		[Parameter (Mandatory = $true)]
		[string]$TargetPath,
		[Parameter (Mandatory = $false)]
		[bool]$ClearTempPath = $false,
		[Parameter (Mandatory = $false)]
		[string]$BIOSPath,
		[Parameter (Mandatory = $false)]
		[string]$ROMPath
	)
	process {
		# Path to extract Garlic to
		$garlicPath = Join-Path -Path $TempPath -ChildPath "\GarlicOS"

		# Cleanup/Create temp path for Garlic extraction
		Remove-GpTemp -TempPath $TempPath -ClearTempPath $ClearTempPath -GarlicPath $garlicPath

		# Download latest version
		try {
			if ($LocalFile -eq "") {
				$garlicZipPath = Invoke-GpDownload -TempPath $TempPath
			}
			else {
				$garlicZipPath = $LocalFile
			}
		}
		catch {
			Write-Error -Message "Error downloading GarlicOS: $($_.Exception.Message)"
		}

		# Decompress the archive
		try {
			Expand-7Zip -ArchiveFileName $garlicZipPath -TargetPath $garlicPath
		}
		catch {
			Write-Error -Message "Error extracting GarlicOS: $($_.Exception.Message)"
		}

		# Doesn't seem to be an easy way to parse the actual version of GarlicOS we have
		# so for now it we'll just overwrite regardless.
		# Would be nice to do a compare before proceeding though...

		# Install GarlicOS
		try {
			# Copy Misc
			$miscDir = "misc"
			Copy-Item -Path (Join-Path -Path $garlicPath -ChildPath $miscDir) -Destination $TargetPath -Recurse -Force -Confirm:$false

			# Copy ROMS
			$romDir = "roms"
			Copy-Item -Path (Join-Path -Path $garlicPath -ChildPath $romDir) -Destination $TargetPath -Recurse -Force -Confirm:$false
		}
		catch {
			Write-Error -Message "Error installing GarlicOS: $($_.Exception.Message)"
		}

		# Copy personal files
		try {
			# BIOS files
			if ($BIOSPath -ne "") {
				# WIP
				#Copy-Item -Path $BIOSPath -Destination $TargetPath -Recurse -Force -Confirm:$false
			}
			# ROM files
			if ($ROMPath -ne "") {
				# WIP
				#Copy-Item -Path $ROMPath -Destination $TargetPath -Recurse -Force -Confirm:$false
			}
		}
		catch {
			Write-Error -Message "Error copying personal game files: $($_.Exception.Message)"
		}

		Write-Host "🧄  GarlicOS successfully installed!" -ForegroundColor DarkYellow
		Write-Host "🙏  Thanks to Black Seraph for GarlicOS - https://www.patreon.com/bePatron?u=8770518" -ForegroundColor DarkMagenta
		Write-Host "☕  Buy the author a coffee if you enjoy this project - https://www.buymeacoffee.com/johnmcc"-ForegroundColor Cyan
	}
}
