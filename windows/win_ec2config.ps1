#!powershell
# This file is part of Ansible
#
# Copyright 2015, Peter Mounce <public@neverrunwithscissors.com>
#
# Ansible is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# Ansible is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with Ansible.  If not, see <http://www.gnu.org/licenses/>.

$ErrorActionPreference = "Stop"

# WANT_JSON
# POWERSHELL_COMMON

$params = Parse-Args $args;
$result = New-Object PSObject;
$result = New-Object psobject @{
    changed = $false
    state_before = @{"Plugins" = @{}}
    updated = @{"Plugins" = @{}}
    sysprep_started = $false
};

if ($params.Ec2HandleUserData)
{
  $Ec2HandleUserData = $params.Ec2HandleUserData.ToString()
  if (($Ec2HandleUserData -ne 'Enabled') -and ($Ec2HandleUserData -ne 'Disabled'))
  {
    Fail-Json $result "Ec2HandleUserData is '$Ec2HandleUserData'; must be 'Enabled' or 'Disabled'"
  }
}
else
{
  $Ec2HandleUserData = "Enabled"
}
if ($params.Ec2SetPassword)
{
  $Ec2SetPassword = $params.Ec2SetPassword.ToString()
  if (($Ec2SetPassword -ne 'Enabled') -and ($Ec2SetPassword -ne 'Disabled'))
  {
    Fail-Json $result "Ec2SetPassword is '$Ec2SetPassword'; must be 'Enabled' or 'Disabled'"
  }
}
else
{
  $Ec2SetPassword = "Enabled"
}
if ($params.sysprep)
{
  $sysprep = $params.sysprep | ConvertTo-Bool
}
else
{
  $sysprep = $false
}


function Read-FileAsXml
{
  [cmdletbinding()]
  param(
    [Parameter(Position=0, Mandatory=$true)] [string] $path
  )
  $content = get-content $path
  return [xml] $content
}

function Modify-PluginConfiguration
{
  [cmdletbinding()]
  param(
    [Parameter(Position=0, Mandatory=$true)] [xml] $xml,
    [Parameter(Position=1, Mandatory=$true)] [psobject] $data
  )
  $xmlElement = $xml.get_DocumentElement()
  $xmlElementToModify = $xmlElement.Plugins
  foreach ($element in $xmlElementToModify.Plugin)
  {
    $result.state_before["Plugins"][$element.name] = $element.State
    foreach ($key in $data.Keys)
    {
      if (($key -eq $element.name) -and (-not($element.State -eq $data[$key])))
      {
        $element.State = $data[$key]
        $result.updated["Plugins"][$element.name] = $data[$key]
        $result.changed = $true
        break;
      }
    }
  }
}

function Run-SysprepAsBackgroundJobAndReturn
{
  [cmdletbinding()]
  param()
  $job_name = "ec2config-sysprep"
  $matching_jobs = Get-ScheduledJob | Where { $_.Name -eq $job_name }
  if ($matching_jobs)
  {
    Unregister-ScheduledJob -Name $job_name
  }
  $invokeScript = {
    Start-Sleep -seconds 3
    & "c:\program files\Amazon\Ec2ConfigService\ec2config.exe" -sysprep
  }
  $result.changed = $true
  Write-Host "Scheduling sysprep for now"
  Register-ScheduledJob -Name $job_name -ScriptBlock $invokeScript -RunNow
  $result.sysprep_started = $true
}


try
{
  $settings_file = "C:\Program Files\Amazon\Ec2ConfigService\Settings\Config.xml"
  $settings = Read-FileAsXml $settings_file
  $data = @{
    'Ec2SetPassword' = $Ec2SetPassword;
    'Ec2HandleUserData' = $Ec2HandleUserData
  }
  Modify-PluginConfiguration $settings $data
  $settings.Save($settings_file)

  if ($sysprep -eq $true)
  {
    Run-SysprepAsBackgroundJobAndReturn
  }

  Exit-Json $result;
}
catch
{
  Fail-Json $result $_.Exception.Message
}
