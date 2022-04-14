# WSLStartService : out of date ! see new version https://github.com/SadarSSI/WSL-WatchDog 
What's new : configuration via a yaml file and prevent last WSL bug / regression see : https://github.com/microsoft/WSL/issues/8161
enjoy !

# WSLStartService : How to make WSL run services at Windows startup without user login
Collection of powershell scripts to automatically start linux wsl1 or wsl2 services when starting windows

wsl_Parameters.ps1: script containing a json array that describes the information needed to:
 - the creation of a windows scheduled task which will be launched each time Windows is restarted (without user login)
 - commands for deleting then (re) creating firewall rules: a specific wsl entry and another for wsl 2
 - commands allowing the creation or deletion of the scheduled task which will be called when Windows starts up

Notes for creating a locally scheduled task
- For a task to be executed when Windows starts up, the account associated with this task must be with administrator rights. By default, in the wsl_Parameters.ps1 file, the username associated with the scheduled task will be the current logged in user. Make sure this account has administrative rights. I have not tested creating a scheduled task with an AD domain account. I have always used a local administrator account

CreateTask.ps1 : script used to create a windows scheduled task by reading the information contained in the wsl_Parameters.ps1 file. 

CreateTask.ps1 needs the following arguments
 -yes or no for the creation of the scheduled task: the value is no by default
- yes or no to create a scheduled task with or without historization, no historization by default

For example :

To create a scheduled task without historisaion
- CreateTask.ps1 yes

Creates a scheduled task and deactivates logging if present
- CreateTask.ps1 yes no

Create a scheduled task with historization (useful for debugging for example)
- CreateTask.ps1 yes yes


StartWSLServices.ps1: script that will be called by the Windows scheduled task for:
- delete then recreate the firewall rules
- start the service (s) contained in the wsl_Parameters.ps1 file

Why do this ?

For example: to connect some remote windows through an ssh tunnel to open an rdp session, a powershell,  ansible or use opensource programs like borgbackup to simply backup  windows users datas in a remote repository through ssh tunnel...and more

 - Yes, it is preferable for me to connect a few windows (not in a domain) with the simplicity of the tools found in linux
 - Yes, I prefer an openssh in a linux wsl because the openssh windows 10 server does not provide access to a linux: just a bash shell
