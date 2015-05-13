# Dependencies:
# Connect-Mstsc (https://gallery.technet.microsoft.com/scriptcenter/Connect-Mstsc-Open-RDP-2064b10b/view/Discussions)
#
#Configuration:
# 1. Change Default File Path to where your credential structure should be. (Line 12)

Function rdp 
{
    Param([Parameter(Mandatory=$true)] $Servername)
    
    #Default File Path
    $path = 'D:\Powershell\Credentials'
    
    #Import Config File
    [xml]$ConfigFile = Get-Content D:\Powershell\Scripts\rdp_settings.xml
    $domains = @{}
    $ConfigFile.settings.ChildNodes | foreach {$domains[$_.Name] = $_.Value}
    
    #Check for Credential Structure
    foreach ($domain in $domains.keys) {
        $user = $domains.Get_Item($domain)
        $useraccount = $user.Split('\')[1]
        $destfolder = $path+'\'+$domain
        $fullpath = $path+'\'+$domain+'\'+$useraccount
        if (!(Test-Path $fullpath)) {
            if (!(Test-Path $destfolder)) {
                New-Item -ItemType directory -Path $destfolder > $null
            }
            (Get-Credential -Credential $user).Password | ConvertFrom-SecureString | Out-File $fullpath
        }
    }
    
    #Get Domain for target server
    $serverdomain = ([System.Net.Dns]::GetHostByName($servername).HostName).Split('.')[1]
    
    #Look up user from found domain
    $user = $domains.Get_Item($serverdomain)
    
    #If user for that domain not found, use default user
    if (!$user) {
        $user = $domains.Get_Item('default')
        $serverdomain = 'default'
    }
    
    $credpath = $path+'\'+$serverdomain+'\'+($user.Split('\')[1])
    
    #Fetch password from secure string    
    $pass = Get-Content $credpath | ConvertTo-SecureString
    $cred = New-Object System.Management.Automation.PSCredential $user,$pass
        
    switch ($servername)
    {
        127.0.0.1 {write-host 'No Remoting to local host'}
        default {
            Connect-Mstsc $servername $user $cred.GetNetworkCredential().password
        }
    }
}