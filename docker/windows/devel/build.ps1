param (
    [string]$ImageName = "fdb-windows",
    [string]$BuildConfig = "Release",
    [string]$Memory,
    [string]$Cpus,
    [switch]$DryRun = $false,
    [switch]$ForceConfigure = $false,
    [switch]$SkipDockerBuild = $false,
    [Parameter(Mandatory = $true)][string]$SourceDir,
    [Parameter(Mandatory = $true)][string]$BuildDir,
    [Parameter(Position = 0)][string]$Target = "installer"
)

# we don't want a trailing \ in the build and source dir
$SourceDir = Resolve-Path $SourceDir
if ($SourceDir.EndsWith("\")) {
    $SourceDir = $SourceDir.Substring(0, $SourceDir.Length - 1)
}
$BuildDir = Resolve-Path $BuildDir
if ($BuildDir.EndsWith("\")) {
    $BuildDir = $BuildDir.Substring(0, $BuildDir.Length - 1)
}

if(!$Memory){
    $Memory = ((Get-CimInstance -ClassName Win32_OperatingSystem).FreePhysicalMemory - (2 * [math]::Pow(2, 20))) * [math]::Pow(2, 10)
}
else{
    $exponent
    $Memory = $Memory.ToUpper()
    if ($Memory.EndsWith("K")) {
        $exponent = 10
    }
    elseif ($Memory.EndsWith("M")) {
        $exponent = 20
    }
    elseif ($Memory.EndsWith("G")) {
        $exponent = 30
    }
    elseif ($Memory.EndsWith("T")) {
        $exponent = 40
    }
    if ($exponent) {
        $Memory = [int64]($Memory.Substring(0, $Memory.Length - 1)) * [Math]::Pow(2, $exponent)
    }
}
if([int64]$Memory -lt (4 * [Math]::Pow(2, 30))){
    Write-Output "The build needs at least 4GB of available memory"
    exit
}

if(!$Cpus){
    $MaxCpusFromMemory = [int]((($Memory / [math]::Pow(2, 30)) - 4) / 2)
    $MaxAvailableCPUs = (Get-CimInstance -ClassName Win32_Processor -Filter "DeviceID='CPU0'").NumberOfLogicalProcessors - 2
    $MaxCPUsToUse = [Math]::Min($MaxCpusFromMemory, $MaxAvailableCPUs)
    $Cpus = $MaxCPUsToUse
}

$GBMemory = [int] ($Memory / [math]::Pow(10, 9))
Write-Output "Using $Cpus CPUs"
Write-Output "Using $GBMemory GB of memory"

$buildCommand = [string]::Format("docker build -t {1} -m {2} .", 
    $SourceDir, $ImageName, $Memory)
if ($DryRun -and !$SkipDockerBuild) {
    Write-Output $buildCommand
}
elseif (!$SkipDockerBuild) {
    Invoke-Expression -Command $buildCommand
}

# Write build instructions into file
$cmdFile = "docker_command.ps1"
$batFile = "$BuildDir\$cmdFile"
$batFileDocker = "C:\fdbbuild\$cmdFile"
# "C:\BuildTools\Common7\Tools\VsDevCmd.bat" | Out-File $batFile
"cd \fdbbuild" | Out-File -Append $batFile
if ($ForceConfigure -or ![System.IO.File]::Exists("$BuildDir\CMakeCache.txt") -or ($Target -eq "configure")) {
    "cmake -G ""Visual Studio 16 2019"" -A x64 -T""ClangCL"" -D ENABLE_SIMULATION_TESTS=ON -S C:\foundationdb -B C:\fdbbuild --debug-trycompile" | Out-File -Append $batFile
}
if ($Target -ne "configure") {
    "msbuild /p:CL_MPCount=$Cpus /p:UseMultiToolTask=true /p:Configuration=$BuildConfig foundationdb.sln" | Out-File -Append $batFile
    #"ctest -j $Cpus --no-compress-output -T test --output-on-failure -C $BuildConfig" | Out-File -Append $batFile
}

$dockerCommand = "powershell.exe -NoLogo -ExecutionPolicy Bypass -File $batFileDocker"
$runCommand = [string]::Format("docker run -v {0}:C:\foundationdb -v {1}:C:\fdbbuild --name fdb-build -m {2} --cpus={3} --rm {4} ""{5}""",
    $SourceDir, $BuildDir, $Memory, $Cpus, $ImageName, $dockerCommand);
if ($DryRun) {
    Write-Output $runCommand
}
else {
    Invoke-Expression $runCommand
}