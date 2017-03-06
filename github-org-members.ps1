if ($args.count -ne 1) {
    Write-Host "ERROR: Usage error: Wrong number of params"
    Write-Host "Param 1: github org name"
    Exit 1
}

# Set params, convert password from secure to plain to be converted to base64 later
$org = $args[0]
$cred = Get-Credential -Message "Enter github credentials"
$username = $cred.username
$password = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($cred.password))

# Pick network/proxy credentials from the system
$browser = New-Object System.Net.WebClient
$browser.Proxy.Credentials =[System.Net.CredentialCache]::DefaultNetworkCredentials

# Convert credetials to Base64 to add to request header
# http://stackoverflow.com/questions/27969362/basic-authentication-with-the-github-api-using-powershell/27970200
function Get_Base64_Creds($username, $password) {
    $str = "{0}:{1}" -f $username,$password
    $bytes = [System.Text.Encoding]::Ascii.GetBytes($str)
    return [Convert]::ToBase64String($bytes)
}
$cred = Get_Base64_Creds $username $password

# Out file header
$out = "LOGIN,URL,EMAIL`r`n"

# Get github org members with login and email (if public)
$i = 0
do {
    $i++
    $r = Invoke-RestMethod -Method Get -Uri "https://api.github.com/orgs/$org/members?page=$i" -Headers @{"Authorization"="Basic $cred"}
    write-host "Page: $i"
    write-host "Size: " $r.count
    for ($j=0; $j -lt $r.count; $j++) {
	$login = $r[$j].login
	$url = $r[$j].url
	$profile = Invoke-RestMethod -Method Get -Uri $url -Headers @{"Authorization"="Basic $cred"}
	$email = $profile.email
	$out += $login + "," + $url + "," + $email + "`r`n"
   }
}
while ($r)

Set-Content out.csv $out
