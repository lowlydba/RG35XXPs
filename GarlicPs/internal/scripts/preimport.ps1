# Place all code that should be run before functions are imported here

# Hacky check for balena cli - needed to flash the .img file to SD
# https://docs.balena.io/reference/balena-cli/
try {
    Invoke-Expression "balena" | Out-Null
}
catch {
    Write-Error -Message "balena cli not installed and/or not in PATH environment."
}
