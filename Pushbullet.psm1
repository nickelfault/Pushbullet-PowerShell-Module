﻿$APIKey = ""

Function Send-Pushbullet
{
    <#
    .SYNOPSIS
        Send-Pushbullet can be used with the Pushbullet service to send notifications to your devices.

    .DESCRIPTION
        This function requires an account at Pushbullet. Register at http://pushbullet.com and obtain your API Key from the account settings section.

        With this module you can send messages or links from a remote system to all of your devices.
   
    .EXAMPLE
        Send-Pushbullet -APIKey "XXXXXX" -Title "Hello World" -Message "This is a test of the notification service."

        Send a message to all your devices.

    .EXAMPLE
        Send-Pushbullet -APIKey "XXXXXX" -Title "Here is a link" -Link "http://pushbullet.com" -DeviceIden "XXXXXX"

        Send a link to one of your deivces. Use Get-PushbulletDevices to get a list of Iden codes.

    .EXAMPLE
        Send-Pushbullet -APIKey "XXXXXX" -Title "Hey there" -Message "Are you here?" -ContactEmail "user@example.com"

        Send a message to a remote user.
    #>
    param([Parameter(Mandatory=$True)][string]$Title=$(throw "Title is mandatory, please provide a value."), [string]$APIKey=$APIKey, [string]$Message="", [string]$Link="", [string]$DeviceIden="", [string]$ContactEmail="")

    if ($APIKey -eq "")
    {
        throw "APIKey is mandatory, please provide a value."
    }

    if($Link -ne "")
    {
        $Body = @{
            type = "link"
            title = $Title
            body = $Message
            url = $Link
            device_iden = $DeviceIden
            email = $ContactEmail
        }
    }
    else
    {
        $Body = @{
            type = "note"
            title = $Title
            body = $Message
            device_iden = $DeviceIden
            email = $ContactEmail
        }
    }

    $Creds = New-Object System.Management.Automation.PSCredential ($APIKey, (ConvertTo-SecureString $APIKey -AsPlainText -Force))
    Invoke-WebRequest -Uri "https://api.pushbullet.com/v2/pushes" -Credential $Creds -Method Post -Body $Body
}

Function Get-PushbulletDevices
{
    <#
    .SYNOPSIS
        Get-PushbulletDevices will return the list of devices currently linked to your Pushbullet account.

    .DESCRIPTION
        This function requires an account at Pushbullet. Register at http://pushbullet.com and obtain your API Key from the account settings section.

        With this module you can retrieve a list of devices linked to your Pushbullet accounts, and then use the 'iden' value to send notifications to specific devices.
   
    .EXAMPLE
        Get-PushbulletDevices -APIKey "XXXXXX" | Select nickname,model,iden

        Get a table of names, models and iden numbers for all your devices.

    .EXAMPLE
        Get-PushbulletDevices -APIKey "XXXXXX" | Where {$_.nickname -eq "MyDevice"} | Select -ExpandProperty iden

        Return the iden value for a specific device called 'MyDevice'.
    #>
    param([string]$APIKey=$APIKey)

    if ($APIKey -eq "")
    {
        throw "APIKey is mandatory, please provide a value."
    }

    $Creds = New-Object System.Management.Automation.PSCredential ($APIKey, (ConvertTo-SecureString $APIKey -AsPlainText -Force))
    $devices = Invoke-WebRequest -Uri "https://api.pushbullet.com/v2/devices" -Credential $Creds -Method GET
    $json = $devices.content | ConvertFrom-Json
    return $json.devices
}

function ExtendJSON($base, $ext)
{
    $propNames = $($ext | Get-Member -MemberType *Property).Name
    foreach ($propName in $propNames) {
        if ($base.PSObject.Properties.Match($propName).Count) {
            if ($base.$propName.GetType().Name -eq "PSCustomObject")
            {
                $base.$propName = ExtendJSON $base.$propName $ext.$propName
            }
            else
            {
                $base.$propName = $ext.$propName
            }
        }
        else
        {
            $base | Add-Member -MemberType NoteProperty -Name $propName -Value $ext.$propName
        }
    }
    return $base
}

Function Get-PushbulletChats
{
    <#
    .SYNOPSIS
        Get-PushbulletChats will return your list of chats.

    .DESCRIPTION
        This function requires an account at Pushbullet. Register at http://pushbullet.com and obtain your API Key from the account settings section.

        With this module you can see a list of your existing chats, for use with Send-Pushbullet and the 'ContactEmail' parameter.
   
    .EXAMPLE
        Get-PushbulletChats -APIKey "XXXXXX"

        Get a table of current chats and contact details.
    #>
    param([string]$APIKey=$APIKey)

    if ($APIKey -eq "")
    {
        throw "APIKey is mandatory, please provide a value."
    }

    $Creds = New-Object System.Management.Automation.PSCredential ($APIKey, (ConvertTo-SecureString $APIKey -AsPlainText -Force))
    $chats = Invoke-WebRequest -Uri "https://api.pushbullet.com/v2/chats" -Credential $Creds -Method GET
	
	return ($chats | ConvertFrom-Json).chats
}

Export-ModuleMember -Function Send-Pushbullet
Export-ModuleMember -Function Get-PushbulletDevices
Export-ModuleMember -Function Get-PushbulletChats
