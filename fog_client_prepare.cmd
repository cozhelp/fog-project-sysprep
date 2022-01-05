@Echo Off
title Fog-Project Sysprep
set this_file=%0
CLS

Set Answer_file_from_git_repo=unattend-Win10-21H1-ImpactLocal.xml
Set FogServer=fogserver.local

Call :Grab_SysPrep_Answer_File %Answer_file_from_git_repo%
Call :Power_Settings
Call :Rename_Computer
Call :Install_Powershell_WU_Tools
Call :Run_Powershell_WU_Tools
Call :Install_Choco
Call :Fog_SmartInstaller %FogServer%
Call :Sysprep

GoTo :EOF



:Grab_SysPrep_Answer_File
if exist "C:\Windows\System32\sysprep\unattend.xml" GoTo :EOF
Set File=%1
echo Grabing SysPrep answer file
curl https://raw.githubusercontent.com/cozhelp/fog-project-sysprep/main/%File% -o "C:\Users\Administrator\Desktop\unattend.xml"
echo.
echo.
echo Do you want to adjust the answer file on the desktop
echo before moving to the sysprep folder?
notepad "C:\Users\Administrator\Desktop\unattend.xml"
pause
move /y "C:\Users\Administrator\Desktop\unattend.xml" "C:\Windows\System32\sysprep\"
echo.
GoTo :EOF



:Rename_Computer
If /i "%ComputerName%" EQU "CHANGE-ME" GoTo :EOF
echo Rename Computer
"%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -InputFormat None -ExecutionPolicy Bypass -Command "Rename-Computer -NewName 'CHANGE-ME'"
echo.
GoTo :EOF



:Power_Settings
echo Adjust Power Settings
powercfg -x -standby-timeout-ac 0
powercfg -x -hibernate-timeout-ac 0
echo.
GoTo :EOF



:Install_Choco
echo Install Choco
@"%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -InputFormat None -ExecutionPolicy Bypass -Command "[System.Net.ServicePointManager]::SecurityProtocol = 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))" && SET "PATH=%PATH%;%ALLUSERSPROFILE%\chocolatey\bin"
echo.
GoTo :EOF



:Fog_SmartInstaller
REM https://docs.fogproject.org/en/latest/getting_started/install_fog_client.html
echo Install Fog's SmartInstaller
Set FogServer=%1
REM Set FogServer=fogserver.local
Set InstallFile=SmartInstaller.exe
curl http://%FogServer%/fog/client/download.php?smartinstaller --output "%InstallFile%"
Start /wait "Fog" "%InstallFile%" --server=%FogServer% -s -t
Del "%InstallFile%"
echo.
GoTo :EOF



:Install_Powershell_WU_Tools
echo Install Powershell Windows Updates Tools
echo y | "%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -InputFormat None -ExecutionPolicy Bypass -Command "Install-Module -Name PSWindowsUpdate -Force"
echo y | "%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -InputFormat None -ExecutionPolicy Bypass -Command "Add-WUServiceManager -MicrosoftUpdate"
echo.
GoTo :EOF



:Run_Powershell_WU_Tools
echo Run Powershell Windows Updates Tools
REM Download and Install Windows Updates
"%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -InputFormat None -ExecutionPolicy Bypass -Command "Install-WindowsUpdate -MicrosoftUpdate -NotCategory "Drivers" -NotKBArticle "KB5005463" -AcceptAll -AutoReboot"
Timeout 30
echo.
GoTo :EOF



:Sysprep
Echo Sysprep and Shutdown
taskkill -f -im Sysprep.exe
net stop wmpnetworksvc
Start "Sysprep" "%WinDir%\system32\sysprep\Sysprep.exe" /generalize /shutdown /oobe
REM Start "Sysprep" "%WinDir%\system32\sysprep\Sysprep.exe" /generalize /oobe /shutdown /unattend:C:\customize\customize.xml
echo Y | del %appdata%\microsoft\windows\recent\automaticdestinations\*
del %this_file%
del %0
echo.
GoTo :EOF
