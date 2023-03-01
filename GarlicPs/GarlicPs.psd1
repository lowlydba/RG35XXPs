@{
	# Script module or binary module file associated with this manifest
	RootModule = 'GarlicPs.psm1'

	# Version number of this module.
	ModuleVersion = '0.1.0'

	# ID used to uniquely identify this module
	GUID = 'd9f6a26f-ede0-4ab7-b894-482bfc9491c7'

	# Author of this module
	Author = 'lowlydba'

	# Copyright statement for this module
	Copyright = 'Copyright (c) 2023 lowlydba / John McCall'

	# Description of the functionality provided by this module
	Description = 'A helper utility for GarlicOS.'

	# Minimum version of the Windows PowerShell engine required by this module
	PowerShellVersion = '5.0'

	# Modules that must be imported into the global environment prior to importing this module
	RequiredModules = @(@{ ModuleName = '7Zip4PowerShell'; ModuleVersion = '2.0.0' })

	# Functions to export from this module
	FunctionsToExport = @('Update-GpGarlic', 'Install-GpGarlic')

	# Cmdlets to export from this module
	CmdletsToExport = ''

	# Variables to export from this module
	VariablesToExport = ''

	# Aliases to export from this module
	AliasesToExport = ''

	# List of all files packaged with this module
	FileList = @()

	# Private data to pass to the module specified in ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
	PrivateData = @{

		#Support for PowerShellGet galleries.
		PSData = @{

			# Tags applied to this module. These help with module discovery in online galleries.
			# Tags = @()

			# A URL to the license for this module.
			# LicenseUri = ''

			# A URL to the main website for this project.
			# ProjectUri = ''

			# A URL to an icon representing this module.
			# IconUri = ''

			# ReleaseNotes of this module
			# ReleaseNotes = ''

		} # End of PSData hashtable

	} # End of PrivateData hashtable
}
