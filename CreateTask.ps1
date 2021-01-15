Param(
 [string]$CreateTask="no",
 [string]$SetHisto="-"
)

Clear-Host

 # $ErrorActionPreference = "silentlycontinue"
$nl = [Environment]::NewLine

Write-Host "Load $PSScriptRoot\wsl_params.ps1..." -ForegroundColor DarkCyan
. "$PSScriptRoot\wsl_params.ps1"

# Write-Host "CreateTask=$CreateTask, SetHisto=$SetHisto, PSScriptRoot=$PSScriptRoot" -ForegroundColor Yellow

if ($CreateTask -eq "yes")
{

  # Self-elevate the script if required
  if (-Not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator')) {
    if ([int](Get-CimInstance -Class Win32_OperatingSystem | Select-Object -ExpandProperty BuildNumber) -ge 6000) {  
      $CommandLine = "-File `"" + $MyInvocation.MyCommand.Path + "`" " + $CreateTask + " " + $SetHisto
      Write-Host "Start-Process -FilePath PowerShell.exe -Verb Runas -ArgumentList $CommandLine"
      Start-Process -FilePath PowerShell.exe -Verb Runas -ArgumentList $CommandLine
      Exit
    }
  }

  $TaskName          = $Params.Task.TaskName
  $unRegister        = $ExecutionContext.InvokeCommand.ExpandString($Params.Task.unRegister)
  $TaskAction        = Invoke-Expression $ExecutionContext.InvokeCommand.ExpandString($Params.Task.TaskAction)
  $TaskUserPrincipal = Invoke-Expression $ExecutionContext.InvokeCommand.ExpandString($Params.Task.TaskUserPrincipal)
  $TaskTrigger       = Invoke-Expression $ExecutionContext.InvokeCommand.ExpandString($Params.Task.TaskTrigger)
  $TaskSettings      = Invoke-Expression $ExecutionContext.InvokeCommand.ExpandString($Params.Task.TaskSettings)

  if( Get-ScheduledTask | Where-Object {$_.TaskName -like $($Params.Task.TaskName) } ) { 
    Write-Host "  - Remove Task $($Params.Task.TaskName)" -ForegroundColor Red
    Write-Host "  - $unRegister" -ForegroundColor Red
    Write-Host "$($nl)"
    Invoke-Expression $unRegister
  } 

  Write-Host "  - TaskAction=$($Params.Task.TaskAction)".Replace('$PSScriptRoot',$PSScriptRoot) -ForegroundColor Yellow
  Write-Host "  - TaskUserPrincipal=$($Params.Task.TaskUserPrincipal)".Replace('$($Params.Task.User)',$($Params.Task.User)) -ForegroundColor Yellow
  Write-Host "  - TaskTrigger=$($Params.Task.TaskTrigger)" -ForegroundColor Yellow
  Write-Host "  - TaskSettings=$($Params.Task.TaskSettings)" -ForegroundColor Yellow
  
  Write-Host "$($nl)  - Register=$($Params.Task.Register)".Replace('$TaskName',$TaskName).Replace(
  '$TaskAction', $($Params.Task.TaskAction).Replace('$PSScriptRoot',$PSScriptRoot)).Replace(
  '$TaskUserPrincipal', $($Params.Task.TaskUserPrincipal).Replace('$($Params.Task.User)',$($Params.Task.User))).Replace(
  '$TaskTrigger', $($Params.Task.TaskTrigger)).Replace(
  '$TaskSettings', $($Params.Task.TaskSettings)) -ForegroundColor Cyan
  
  Invoke-Expression "$($Params.Task.Register)"
}

if ( $SetHisto.Length -gt 1 )
{

  # Self-elevate the script if required
  if (-Not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator')) {
    if ([int](Get-CimInstance -Class Win32_OperatingSystem | Select-Object -ExpandProperty BuildNumber) -ge 6000) {  
      $CommandLine = "-File `"" + $MyInvocation.MyCommand.Path + "`" " + $CreateTask + " " + $SetHisto
      Write-Host "Start-Process -FilePath PowerShell.exe -Verb Runas -ArgumentList $CommandLine"
      Start-Process -FilePath PowerShell.exe -Verb Runas -ArgumentList $CommandLine
      Exit
    }
  }  
  
  if ($SetHisto -eq "yes") { $action = "`$True" } else { $action = "`$False" }
  
  $EnableHisto = $ExecutionContext.InvokeCommand.ExpandString($Params.Task.EnableHisto) + $action

  Write-Output "" 
  # Write-Output "action=$action" 
  # Write-Host "  - EnableHisto=$EnableHisto" -ForegroundColor Yellow
  Invoke-Expression $($EnableHisto)
}  

Write-Host "Press any key to continue..."
$Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
