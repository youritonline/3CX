################################################################
#                                                              #
#           3CX Logo Upadter Information Script                # 
#                                                              #
# Note: 1. Storing Credentials in a script is not recomended!  #
#       2. Running this script is at your own risk             #
#                                                              #
#                                                              #
# Script By: Yourit.online                                     #
################################################################

### Update the details here:

$3cxurl  = '' #Enter your url here including the trailing forward slash (eg. https://xyz.3cx.com.au/)
$3cxuser = '' #3cx admin user, consider creating a restricterd admin user 
$3cxpass = '' #3cx Password
#commented line out as line 71 now looks up the logo filename from the system
#$logo="" #set this to match the logo file name in 3CX


### Start Script


$3cxcreds = "{`"Username`":`"$3cxuser`",`"Password`":`"$3cxpass`"}"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$headers = @{
    "Accept"="application/json, text/plain, */*"; 
    "Referer"="$($3cxurl)"; 
    "Origin"="$($3cxurl)"; 
    "User-Agent"="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/75.0.3770.100 Safari/537.36"
    }
    
#try to login    
$login = Invoke-WebRequest -Uri "$($3cxurl)api/login" `
    -Method "POST" -Headers $headers -ContentType "application/json;charset=UTF-8" -Body $3cxcreds -SessionVariable sesh

if ($login.StatusCode -ne "200") {
    throw "Login to 3CX failed: $($login.content)"
    exit #exit if login failed
} else { 

#continue if login successful

# get list of all extensions / users
$Extns = (irm -Uri "$($3cxurl)api/ExtensionList" -websession $sesh).list

}

# Loop through the extensions
$Extns |% {
    Write-Host "Checking Logo for:" -ForegroundColor Green
    Write-host "ID: $($_.id)"
    Write-host "Name: $($_.FirstName)"
    Write-host "Ext: $($_.Number)"
    $Ext = iwr -Uri "$($3cxurl)api/ExtensionList/set" -Method Post -websession $sesh -Body "{`"Id`":$($_.id)}" -ContentType "application/json;charset=UTF-8" 
    $customProfiles = iwr -uri "$($3cxurl)api/CustomParametersList/getCustomProfileNames" -Method Get -websession $sesh -ContentType "application/json;charset=UTF-8" 
    $queues = iwr -uri "$($3cxurl)api/queueList/getQueuesByAgent?extensionNumber=$($_.number)" -Method Get -websession $sesh -ContentType "application/json;charset=UTF-8" 
    $ExtID = ($Ext.Content |ConvertFrom-Json).id
    $PhoneDevices = ($Ext.Content |ConvertFrom-Json).activeobject.PhoneDevices 
    $phones = $PhoneDevices._value
    $phones | % {
        Write-host "phone ID: $($_.id)"
        Write-host "phone model: $($_.model._value)"
        Write-host "phone Logo: $($_.PhoneLogo.selected)"
        Write-host "phone Logos available: $($_.PhoneLogo.possibleValues)"
        if ($null -eq $($_.PhoneLogo.possibleValues)){
            write-host "Phone does not support logos" -ForegroundColor Magenta
            return
        }
        $readPropertyBody = "{`"Path`":{`"ObjectId`":$ExtID,`"PropertyPath`":[{`"Name`":`"PhoneDevices`",`"IdInCollection`":$($_.id)},{`"Name`":`"PhoneLogo`"}]},`"State`":{`"Start`":0,`"Search`":`"`"},`"Count`":1000}"
        #lookup the Possible Values for logos
        $readProperty = iwr -Uri "$($3cxurl)api/edit/readProperty" -Method Post -Headers $headers -websession $sesh -Body $readPropertyBody -ContentType "application/json;charset=UTF-8" 
        #set the logo to the 2nd option (index #1)
        $logo = ($readProperty.Content |convertfrom-json).PossibleValues[1]
        $logobody = "{`"Path`":{`"ObjectId`":$ExtID,`"PropertyPath`":[{`"Name`":`"PhoneDevices`",`"IdInCollection`":$($_.id)},{`"Name`":`"PhoneLogo`"}]},`"PropertyValue`":`"$logo`"}"
        $UpdateLogo = iwr -Uri "$($3cxurl)api/edit/update" -Method Post -Headers $headers -websession $sesh -Body $logobody -ContentType "application/json;charset=UTF-8" 
        # write-host "test body: $logobody"
    }
   $Save = iwr -Uri "$($3cxurl)api/edit/save" -Method Post -websession $sesh -Body "$extID" -ContentType "application/json;charset=UTF-8" 
   
    }


