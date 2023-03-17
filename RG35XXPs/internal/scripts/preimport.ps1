# Place all code that should be run before functions are imported here

# Hacky check for balena cli - needed to flash the .img file to SD
# https://docs.balena.io/reference/balena-cli/
try {
    Invoke-Expression "balena" | Out-Null
}
catch {
    Write-Error -Message "balena cli not installed and/or not in PATH environment."
}

# Hacky check for 7zip cli - needed since Batocera is distribued as .7zip
try {
    Invoke-Expression "7z" | Out-Null
}
catch {
    Write-Error -Message "7zip (cli) not installed and/or not in PATH environment."
}
