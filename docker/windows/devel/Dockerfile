# Use the latest FoundationDB Windows Build image
#FROM foundationdb/foundationdb-build-windows:0.2.0
FROM fdb-windows
# Define the entry point for the docker container.
# This entry point starts the developer command prompt and launches the PowerShell shell.
ENTRYPOINT ["C:\\BuildTools\\Common7\\Tools\\VsDevCmd.bat", "&&", "powershell.exe", "-NoLogo", "-ExecutionPolicy", "Bypass"]