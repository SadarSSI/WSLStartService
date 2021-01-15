# Self-elevate the script if required
if (-Not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator')) {
  if ([int](Get-CimInstance -Class Win32_OperatingSystem | Select-Object -ExpandProperty BuildNumber) -ge 6000) {  
    $CommandLine = "-File `"" + $MyInvocation.MyCommand.Path + "`" " 
    Write-Host "Start-Process -FilePath PowerShell.exe -Verb Runas -ArgumentList $CommandLine"
    Start-Process -FilePath PowerShell.exe -Verb Runas -ArgumentList $CommandLine
    Exit
  }
}
  
Clear-Host

# $ErrorActionPreference = "silentlycontinue"
$nl = [Environment]::NewLine

Write-Host "Load $PSScriptRoot\wsl_params.ps1..." -ForegroundColor DarkCyan
. "$PSScriptRoot\wsl_params.ps1"

Function GetRuleProfiles {
  $RuleProfile = ""
  # Profile constitution
  foreach ($Profile in $Params.Ports[$Port].Profile) 
    { 
      if ($RuleProfile.Length -eq 0){
        $RuleProfile = "profile=" + $Profile
      }else{
        $RuleProfile = $RuleProfile + "," + $Profile
      }
      
    }
    # Write-Output "RuleProfile=$RuleProfile"
    return $RuleProfile
}

Function WSL1_CreateRule {
  # Write-Host "$($nl)"
  $DelFirewallRule = $ExecutionContext.InvokeCommand.ExpandString($Params.wsl1.DelFirewallRule)
  $AddFirewallRule = $ExecutionContext.InvokeCommand.ExpandString($Params.wsl1.AddFirewallRule)

  if ($(Get-NetFirewallPortFilter | Where LocalPort -eq $Port)){
    Write-Host "$($nl)  $DelFirewallRule" -ForegroundColor Yellow
    Invoke-Expression $DelFirewallRule | out-null
  }
  
  # Write-Host  "" -NoNewline
  Write-Host  "  $AddFirewallRule" -ForegroundColor Yellow
  Invoke-Expression $AddFirewallRule | out-null
}
Function WSL2_CreateRule {
  $DelProxyv4Tov4  = $ExecutionContext.InvokeCommand.ExpandString($Params.wsl2.DelProxyv4Tov4)
  $DelFirewallRule  = $ExecutionContext.InvokeCommand.ExpandString($Params.wsl2.DelFirewallRule)
  $AddProxyV4ToV4  = $ExecutionContext.InvokeCommand.ExpandString($Params.wsl2.AddProxyV4ToV4)
  $AddFirewallRule = $ExecutionContext.InvokeCommand.ExpandString($Params.wsl2.AddFirewallRule)

  if ($(Get-NetFirewallPortFilter | Where LocalPort -eq $Port)){
    Write-Host "$($nl)  $DelFirewallRule" -ForegroundColor Red
    Invoke-Expression $DelFirewallRule | out-null
  }
  
  Write-Host "  $DelProxyv4Tov4 $($nl)"  -ForegroundColor Red
  Invoke-Expression $DelProxyv4Tov4

  Write-Host "  $AddProxyV4ToV4" -ForegroundColor Yellow
  Invoke-Expression $AddProxyV4ToV4 | out-null
  
  Write-Host "  $AddFirewallRule $($nl)" -ForegroundColor Yellow
  Invoke-Expression $AddFirewallRule | out-null
}
Function CheckTCPPort {
  $tcp = New-Object -TypeName  System.Net.Sockets.TCPClient
  Write-Output "Test Port $Port"
  try
  {
    $tcp.Connect("localhost",$Port)
    $tcp.Connected

    Write-Output "Port $Port is open"
    Write-Output "Nothing to do..."
    }catch{
    Write-Output "Port $Port is close"
  }
  $tcp.Close()
}

Function QueryFirewallRules{
  # Query Firewall Rules with localport equal...
  $cmd = "Get-NetFirewallPortFilter | Where LocalPort -eq 11098 | Get-NetFirewallRule | 
  Format-Table -Property Name, DisplayName, DisplayGroup, Enabled, Action, Direction, Profile,
  @{Name='Protocol';Expression={($PSItem | Get-NetFirewallPortFilter).Protocol}},
  @{Name='LocalPort';Expression={($PSItem | Get-NetFirewallPortFilter).LocalPort}},
  @{Name='RemotePort';Expression={($PSItem | Get-NetFirewallPortFilter).RemotePort}},
  @{Name='RemoteAddress';Expression={($PSItem | Get-NetFirewallAddressFilter).RemoteAddress}}"

  # see
  # https://stackoverflow.com/questions/42110526/why-doesnt-get-netfirewallrule-show-all-information-of-the-firewall-rule
  # https://itluke.online/2018/11/27/how-to-display-firewall-rule-ports-with-powershell/

}

Function CreateFirewallRules {
  # Delete & Create Firewall Rules for each port(s) & protocol(s)
  foreach ( $Port in ($Params.Ports).keys )
  {

    $RuleProfile = ""
    $RuleProfile = GetRuleProfiles   
    # Write-Output "RuleProfile=$RuleProfile"

    foreach ($Protocol in $Params.Ports[$Port].Protocol) 
      { 
        
        $RuleName = $ExecutionContext.InvokeCommand.ExpandString($Params.Ports[$Port].RuleDescript)
        # Write-Output "Port=$Port, Protocol=$Protocol, RuleName=$RuleName, RuleProfile=$RuleProfile"
        
        if ($WSLVer -eq "1")
        {
          WSL1_CreateRule
        }else{
          WSL2_CreateRule
        }
      }
  }

  # Start service(s) into distro (...)
  foreach ( $Service in ($Params.Services))
  {
    $StartService = "wsl.exe --distribution " + $Params.Distro + " " + $Service
    Write-Host "$($nl)  Start Service : " -ForegroundColor Magenta -NoNewline
    Write-Host "$StartService $($nl)".Replace('$Port', $Port) -ForegroundColor Yellow
    Invoke-Expression $StartService 

  }
}

# StopWSL
$StopWSL = $ExecutionContext.InvokeCommand.ExpandString($Params.StopWSL)
Write-Host "$($nl)  $StopWSL" -ForegroundColor Red
Invoke-Expression $StopWSL

# GetWSLVer
$WSLVer = $($ExecutionContext.InvokeCommand.ExpandString($Params.GetWSLVer)).split(" ")[-3]

# Get@IP
$WSLIP = $ExecutionContext.InvokeCommand.ExpandString($Params.GetIPCmd)

# Dsiplay result
Write-Host "  Distribution : $($Params.Distro), WSL Version :$WSLVer, IP Address : $WSLIP" -ForegroundColor Yellow

# CreateFirewallRules
CreateFirewallRules

Write-Host "$($nl) Done !" -ForegroundColor DarkGreen
Write-Host "Press any key to continue..."
$Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
