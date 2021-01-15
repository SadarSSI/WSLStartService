# Set Parameters
$Params = @{

  Distro    = 'Arch'
  StopWSL   = 'wsl.exe --distribution $($Params.Distro) --shutdown'
  GetWSLVer = '$(wsl.exe --distribution $($Params.Distro) --list --all --verbose)'
  GetIPCmd  = '$(wsl.exe --distribution $($Params.Distro) ip route get 1.1.1.1 | grep -oP "src \K\S+")'
  # Services  = ('sudo systemctl restart sshd; netstat -an | grep -ai list | grep -ai 11098')
  Services  = ('sudo systemctl restart sshd; netstat -an | findstr -i list | findstr -i $Port')
  Ports = @{
    11098 = @{
      Protocol     = ('TCP')
      RuleDescript = 'WLS_$Port $Protocol'
      Profile      = ('domain','private')
    }
  }      
  
  wsl1 = @{
    # DelFirewallRule = 'Remove-NetFirewallRule -InputObject $(Get-NetFirewallPortFilter | Where LocalPort -eq xxx | Get-NetFirewallRule)'
    DelFirewallRule = 'netsh advfirewall firewall delete rule name=all protocol=$Protocol localport=$Port'
    AddFirewallRule = 'netsh advfirewall firewall add rule name="$RuleName" dir=in action=allow protocol=$Protocol localport=$Port $RuleProfile'
  }
  
  wsl2 = @{
    DelProxyV4ToV4  = 'netsh int portproxy delete v4tov4 listenaddress=0.0.0.0 listenport=$Port'
    DelFirewallRule = 'netsh advfirewall firewall delete rule name=all protocol=$Protocol localport=$Port'
    AddProxyV4ToV4  = 'netsh interface portproxy add v4tov4 listenaddress=0.0.0.0 listenport=$Port connectaddress=$wslip connectport=$Port'
    AddFirewallRule = 'netsh advfirewall firewall add rule name="$RuleName" dir=in action=allow protocol=$Protocol localport=$Port $RuleProfile'
  }  
  
  Task = @{
    User     = "$env:username"
    TaskName = "Wsl_"
    TaskAction        = 'New-ScheduledTaskAction -Execute Powershell.exe -Argument "-executionpolicy remotesigned -File ""$PSScriptRoot\StartWSLServices.ps1""" -WorkingDirectory "$PSScriptRoot" '
    TaskTrigger       = 'New-ScheduledTaskTrigger -AtStartup'
    TaskUserPrincipal = 'New-ScheduledTaskPrincipal -UserId "$($Params.Task.User)" -RunLevel Highest -LogonType S4U'
    TaskSettings      = 'New-ScheduledTaskSettingsSet -ExecutionTimeLimit (New-TimeSpan -Minutes 20) -RestartCount 3 -RestartInterval (New-TimeSpan -Minutes 60) -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -RunOnlyIfNetworkAvailable -DontStopOnIdleEnd -Compatibility Win8'
    Register          = 'Register-ScheduledTask -TaskName "$TaskName" -Action $TaskAction -Principal $TaskUserPrincipal -Trigger $TaskTrigger -Settings $TaskSettings -Force'

    unRegister        = 'Unregister-ScheduledTask -TaskName "$($Params.Task.TaskName)" -Confirm:`$False'
    EnableHisto       = "wevtutil set-log Microsoft-Windows-TaskScheduler/Operational /enabled:$($action)"
  }
}
