# escape=`
ARG IMAGE_TAG=0.2.0

# Use the latest Windows Server Core image with .NET Framework 4.8.
FROM mcr.microsoft.com/dotnet/sdk:6.0-windowsservercore-ltsc2019

# Restore the default Windows shell for correct batch processing.
SHELL ["cmd", "/S", "/C"]

# Download the Build Tools bootstrapper.
ADD https://aka.ms/vs/16/release/vs_buildtools.exe C:\TEMP\vs_buildtools.exe

# Install Build Tools with the Microsoft.VisualStudio.Workload.AzureBuildTools workload, excluding workloads and components with known issues.
RUN C:\TEMP\vs_buildtools.exe --quiet --wait --norestart --nocache `
    --installPath C:\BuildTools `
    --add Microsoft.VisualStudio.Workload.VCTools `
    --add Microsoft.VisualStudio.Component.TestTools.BuildTools `
    --add Microsoft.VisualStudio.Component.VC.ASAN `
    --add Microsoft.VisualStudio.Component.VC.CMake.Project `
    --add Microsoft.VisualStudio.Component.VC.Tools.x86.x64 `
    --add Microsoft.VisualStudio.Component.Windows10SDK.18362 `
    --add Microsoft.VisualStudio.Component.VC.Llvm.ClangToolset `
    --add Microsoft.VisualStudio.Component.VC.Llvm.Clang `
 || IF "%ERRORLEVEL%"=="3010" EXIT 0

# Install Choco package manager
RUN powershell -Command "iwr https://chocolatey.org/install.ps1 -UseBasicParsing | iex"
RUN powershell -Command choco install 7zip -y

# Download boost
# We want to make this as early as possible as downloading and unpacking boost takes a very long time
RUN mkdir C:\Downloads && `
    powershell -Command iwr -Uri https://boostorg.jfrog.io/ui/api/v1/download?repoKey=main\"&\"path=release%252F1.76.0%252Fsource%252Fboost_1_76_0.7z -OutFile C:\Downloads\boost_1_76_0.7z && `
    powershell -Command If ((Get-FileHash C:\Downloads\boost_1_76_0.7z).Hash -ne \"88782714F8701B6965F3FCE087A66A1262601DD5CCD5B2E5305021BEB53042A1\") { throw \"Hash does not match expected value!!\" } && `
    cd \Downloads && "C:\Program Files\7-Zip\7z" x boost_1_76_0.7z && del boost_1_76_0.7z

# install other dependencies
RUN powershell -Command choco install cmake openjdk12 python -y

# add cmake to the path
RUN setx path "%path%;C:\Program Files\CMake\bin;C:\Program Files\7-Zip;C:\Program Files (x86)\Microsoft Visual Studio\installer"

# Compile boost context
RUN C:\BuildTools\Common7\Tools\VsDevCmd.bat && `
    cd \Downloads\boost_1_76_0 && `
    .\bootstrap.bat && `
    powershell -Command `
    .\b2 variant=release address-model=64 architecture=x86 link=static --with-context --build-type=minimal --layout=system `
        -j((Get-WmiObject -Class Win32_Processor).NumberOfLogicalProcessors)

# CMake's find_package wouldn't be able to find this otherwise
RUN setx CMAKE_PREFIX_PATH "C:\Downloads\boost_1_76_0\stage\"

LABEL version=${IMAGE_TAG}
ENV DOCKER_IMAGEVER=${IMAGE_TAG}

# Enable Windows Update Service (which is required to get .Net Core which is a dependency for wix) and install .Net framework
RUN powershell "Set-Service -Name wuauserv -StartupType Manual; Install-WindowsFeature -Name NET-Framework-Features -Verbose"

# Install WIX
RUN powershell -Command choco install wixtoolset --version 3.11.2 -y

# Install git (for Google test and benchmark)
RUN powershell -Command choco install git -y

# Define the entry point for the docker container.
# This entry point starts the developer command prompt and launches the PowerShell shell.
ENTRYPOINT ["C:\\BuildTools\\Common7\\Tools\\VsDevCmd.bat", "&&", "powershell.exe", "-NoLogo", "-ExecutionPolicy", "Bypass"]
