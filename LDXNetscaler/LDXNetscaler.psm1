function New-NSCredentials {
   Param(
       [Parameter(Mandatory=$false)]
       [PSCredential]
       $Credentials,
       [Parameter(Mandatory=$false)]
       [string]
       $Username,
       [Parameter(Mandatory=$false)]
       [string]
       $Password
   )

   if ($Username -and $Password) {
      $SecurePassword=ConvertTo-SecureString $Password -AsPlainText -Force
      $Credentials=New-Object System.Management.Automation.PSCredential ($Username,$SecurePassword)
   }

   if (!$Credentials) {
      if (!$Username) {
         $Credentials=Get-Credential -Message "Please type username and password"
      } else {
         $Credentials=Get-Credential -UserName $Username -Message "Please type the password"
      }
   }
   
   return $Credentials
}

function Get-NSEnvironment {
    Param (
        [Parameter(Mandatory=$true)]
        [string]
        $Environment
    )

    $JSONPath = Join-Path -Path (Split-Path (get-module -name LDXNetscaler).path) -ChildPath "netscaler.json"
    $NS = Get-Content -Raw -Path $JSONPath | ConvertFrom-Json
    return ($NS.netscaler | Where-Object {$_.Environment -eq $Environment}).NSApi
}

function Get-NSServicesFromServer {
    Param(
        [Parameter(Mandatory=$true, Position=0)]
        [ValidateSet("QA", "PROD","QA-AZ", "PROD-AZ")]
        [string]
        $Environment,
        [Parameter(Mandatory=$true)]
        [string]
        $Server,
        [Parameter(Mandatory=$false)]
        [PSCredential]
        $Credentials,
        [Parameter(Mandatory=$false)]
        [string]
        $Username,
        [Parameter(Mandatory=$false)]
        [string]
        $Password
    )

    $Credentials = New-NSCredentials -Credentials $Credentials -Username $Username -Password $Password
    $fqdn = Get-NSEnvironment -Environment $Environment

    $contenttype = "application/vnd.com.citrix.netscaler.service+json"
    $method = "GET"

    $uri = "${fqdn}/nitro/v1/config/server_binding/${Server}"

    $SvrObject=Invoke-RestMethod -Method ${method} -Uri ${uri} -ContentType ${contenttype} -Headers @{"X-NITRO-USER"=$Credentials.UserName;"X-NITRO-PASS"=$Credentials.GetNetworkCredential().password;}

    foreach ($svc in ($SvrObject.server_binding).server_service_binding) { $svc.servicename }
}

function Get-NSServicesFromLBServer {
    Param(
        [Parameter(Mandatory=$true, Position=0)]
        [ValidateSet("QA", "PROD","QA-AZ", "PROD-AZ")]
        [string]
        $Environment,
        [Parameter(Mandatory=$true)]
        [string]
        $LB,
        [Parameter(Mandatory=$false)]
        [PSCredential]
        $Credentials,
        [Parameter(Mandatory=$false)]
        [string]
        $Username,
        [Parameter(Mandatory=$false)]
        [string]
        $Password
    )

    $Credentials = New-NSCredentials -Credentials $Credentials -Username $Username -Password $Password
    $fqdn = Get-NSEnvironment -Environment $Environment

    $contenttype = "application/vnd.com.citrix.netscaler.service+json"
    $method = "GET"

    $uri = "${fqdn}/nitro/v1/config/lbvserver_service_binding/${LB}"

    $SvrObject=Invoke-RestMethod -Method ${method} -Uri ${uri} -ContentType ${contenttype} -Headers @{"X-NITRO-USER"=$Credentials.UserName;"X-NITRO-PASS"=$Credentials.GetNetworkCredential().password;}

    foreach ( $svc in ($SvrObject.lbvserver_service_binding).servicename) { 
       $svc
    }
}

function Get-NSServersFromLBServer {
    Param(
        [Parameter(Mandatory=$true, Position=0)]
        [ValidateSet("QA", "PROD","QA-AZ", "PROD-AZ")]
        [string]
        $Environment,
        [Parameter(Mandatory=$true)]
        [string]
        $LB,
        [Parameter(Mandatory=$false)]
        [PSCredential]
        $Credentials,
        [Parameter(Mandatory=$false)]
        [string]
        $Username,
        [Parameter(Mandatory=$false)]
        [string]
        $Password
    )

    $Credentials = New-NSCredentials -Credentials $Credentials -Username $Username -Password $Password
    $fqdn = Get-NSEnvironment -Environment $Environment

    $contenttype = "application/vnd.com.citrix.netscaler.service+json"
    $method = "GET"

     foreach ($svc in (Get-NSServicesFromLBServer -Environment $Environment -LB $LB -Credentials $Credentials)) {
        $uri="${fqdn}/nitro/v1/config/service/${svc}"
        $svcobject=Invoke-RestMethod -Method ${method} -Uri ${uri} -ContentType ${contenttype} -Headers @{"X-NITRO-USER"=$Credentials.UserName;"X-NITRO-PASS"=$Credentials.GetNetworkCredential().password;}
        $svcobject.service.servername
    }
}

function Get-NSServerFromService {
    Param(
        [Parameter(Mandatory=$true, Position=0)]
        [ValidateSet("QA", "PROD","QA-AZ", "PROD-AZ")]
        [string]
        $Environment,
        [Parameter(Mandatory=$true)]
        [string]
        $Service,
        [Parameter(Mandatory=$false)]
        [PSCredential]
        $Credentials,
        [Parameter(Mandatory=$false)]
        [string]
        $Username,
        [Parameter(Mandatory=$false)]
        [string]
        $Password
    )
    $Credentials = New-NSCredentials -Credentials $Credentials -Username $Username -Password $Password
    $fqdn = Get-NSEnvironment -Environment $Environment

    $contenttype = "application/vnd.com.citrix.netscaler.service+json"
    $method = "GET"
        
    $uri = "${fqdn}/nitro/v1/config/service/${Service}"

    $SvrObject=Invoke-RestMethod -Method ${method} -Uri ${uri} -ContentType ${contenttype} -Headers @{"X-NITRO-USER"=$Credentials.UserName;"X-NITRO-PASS"=$Credentials.GetNetworkCredential().password;}

    $Svrobject.service.servername
}

function Get-NSLBServerFromService {
    Param(
        [Parameter(Mandatory=$true, Position=0)]
        [ValidateSet("QA", "PROD","QA-AZ", "PROD-AZ")]
        [string]
        $Environment,
        [Parameter(Mandatory=$true)]
        [string]
        $Service,
        [Parameter(Mandatory=$false)]
        [PSCredential]
        $Credentials,
        [Parameter(Mandatory=$false)]
        [string]
        $Username,
        [Parameter(Mandatory=$false)]
        [string]
        $Password
    )

    $Credentials = New-NSCredentials -Credentials $Credentials -Username $Username -Password $Password
    $fqdn = Get-NSEnvironment -Environment $Environment

    $contenttype = "application/vnd.com.citrix.netscaler.service+json"
    $method = "GET"
    $uri = "${fqdn}/nitro/v1/config/svcbindings/${Service}"
    $SvrObject=Invoke-RestMethod -Method ${method} -Uri ${uri} -ContentType ${contenttype} -Headers @{"X-NITRO-USER"=$Credentials.UserName;"X-NITRO-PASS"=$Credentials.GetNetworkCredential().password;}
    foreach ($lb in $SvrObject.svcbindings) { $lb.vservername }
}

function Wait-NSService {
    Param(
        [Parameter(Mandatory=$true)]
        [string]
        $Service,
        [Parameter(Mandatory=$true)]
        [ValidateSet("QA", "PROD","QA-AZ", "PROD-AZ")]
        [string]
        $Environment,
        [Parameter(Mandatory=$false)]
        [bool]
        $RunOnce = $true,
         [Parameter(Mandatory=$false)]
        [PSCredential]
        $Credentials,
        [Parameter(Mandatory=$false)]
        [ValidateSet("UP", "OUT OF SERVICE")]
        [string]
        $ExpectedState='UP',
        [Parameter(Mandatory=$false)]
        [string]
        $Username,
        [Parameter(Mandatory=$false)]
        [string]
        $Password
    )

    $Credentials = New-NSCredentials -Credentials $Credentials -Username $Username -Password $Password
    $fqdn = Get-NSEnvironment -Environment $Environment

    $uri = "${fqdn}/nitro/v1/stat/service/${service}"
    $contenttype = "application/vnd.com.citrix.netscaler.service+json"
    $method = "GET"
    [bool] $SVCNotFound=$false

    do {
       try {
          $svcobject=Invoke-RestMethod -Method ${method} -Uri ${uri} -ContentType ${contenttype} -Headers @{"X-NITRO-USER"=$Credentials.UserName;"X-NITRO-PASS"=$Credentials.GetNetworkCredential().password;}
          $svcstate=$svcobject.service.state

          $str = "${service} is ${svcstate} " + (Get-date -format 'HH:mm:ss') + "           "
          if ($RunOnce -eq $false) {
             Write-Host "`r ${str}" -NoNewline
             if ($svcstate -ne $ExpectedState) { sleep -Seconds 5 }
          } else {
             Write-Output $str
          }
       }
       catch {
          $SVCNotFound=$true
          "error"
       }
    } until ($svcstate -eq $ExpectedState -or $RunOnce -ne $false -or $SVCNotFound)
    if ($RunOnce -ne $true) { write-host }
}

function Start-NSService {
    Param(
        [Parameter(Mandatory=$true)]
        [ValidateSet("QA", "PROD","QA-AZ", "PROD-AZ")]
        [string]
        $Environment,
        [Parameter(Mandatory=$true)]
        [string]
        $Service,
        [Parameter(Mandatory=$false)]
        [PSCredential]
        $Credentials,
        [Parameter(Mandatory=$false)]
        [string]
        $Username,
        [Parameter(Mandatory=$false)]
        [string]
        $Password
    )

    $Credentials = New-NSCredentials -Credentials $Credentials -Username $Username -Password $Password
    $fqdn = Get-NSEnvironment -Environment $Environment

    $uri = "${fqdn}/nitro/v1/config/service?action=enable"
    $contenttype = "application/vnd.com.citrix.netscaler.service+json"
    $method = "POST"

$json = @"
{
    "params": 
    {
        "warning": "YES",
        "onerror": "ROLLBACK",
        "action": "enable"
    },
    "service": 
    {
        "name": "${Service}"
    }
}
"@
    
    Invoke-RestMethod -Method ${method} -Uri ${uri} -ContentType ${contenttype} -Headers @{"X-NITRO-USER"=$Credentials.UserName;"X-NITRO-PASS"=$Credentials.GetNetworkCredential().password;} -Body $json
}

function Stop-NSService {
    Param(
        [Parameter(Mandatory=$true)]
        [ValidateSet("QA", "PROD","QA-AZ", "PROD-AZ")]
        [string]
        $Environment,
        [Parameter(Mandatory=$true)]
        [string]
        $Service,
        [Parameter(Mandatory=$false)]
        [int]
        $Delay=5,
        [Parameter(Mandatory=$false)]
        [PSCredential]
        $Credentials,
        [Parameter(Mandatory=$false)]
        [string]
        $Username,
        [Parameter(Mandatory=$false)]
        [string]
        $Password
    )

    $Credentials = New-NSCredentials -Credentials $Credentials -Username $Username -Password $Password
    $fqdn = Get-NSEnvironment -Environment $Environment

    $uri = "${fqdn}/nitro/v1/config/service?action=disable"
    $contenttype = "application/vnd.com.citrix.netscaler.service+json"
    $method = "POST"

$json = @"
{
    "params": 
    {
        "warning": "YES",
        "onerror": "ROLLBACK",
        "action": "disable"
    },
    "service": 
    {
        "name": "${Service}",
        "delay": $delay,
        "graceful": "NO"
    }
}
"@
    
    Invoke-RestMethod -Method ${method} -Uri ${uri} -ContentType ${contenttype} -Headers @{"X-NITRO-USER"=$Credentials.UserName;"X-NITRO-PASS"=$Credentials.GetNetworkCredential().password;} -Body $json
}

function Set-NSServerIPAddress {
    Param(
        [Parameter(Mandatory=$true)]
        [ValidateSet("QA", "PROD","QA-AZ", "PROD-AZ")]
        [string]
        $Environment,
        [Parameter(Mandatory=$true)]
        [string]
        $Server,
        [Parameter(Mandatory=$true)]
        [string]
        $IPAddress,
        [Parameter(Mandatory=$false)]
        [PSCredential]
        $Credentials,
        [Parameter(Mandatory=$false)]
        [string]
        $Username,
        [Parameter(Mandatory=$false)]
        [string]
        $Password
    )

    $Credentials = New-NSCredentials -Credentials $Credentials -Username $Username -Password $Password
    $fqdn = Get-NSEnvironment -Environment $Environment

    $uri = "${fqdn}/nitro/v1/config/server"
    $contenttype = "application/json"
    $method = "PUT"

$json = @"
{
    "params": 
    {
        "warning": "YES",
        "onerror": "ROLLBACK",
        "action": "enable"
    },
    "server": 
    {
        "name": "${Server}",
        "ipaddress": "${IPAddress}"
    }
}
"@
    
    Invoke-RestMethod -Method ${method} -Uri ${uri} -ContentType ${contenttype} -Headers @{"X-NITRO-USER"=$Credentials.UserName;"X-NITRO-PASS"=$Credentials.GetNetworkCredential().password;} -Body $json
}

function Switch-NSBlueGreen {
    Param(
        [Parameter(Mandatory=$true)]
        [ValidateSet("QA", "PROD","QA-AZ", "PROD-AZ")]
        [string]
        $Environment,
        [Parameter(Mandatory=$false)]
        [string]
        $LBBlue,
        [Parameter(Mandatory=$false)]
        [string]
        $LBGreen,
        [Parameter(Mandatory=$false)]
        [PSCredential]
        $Credentials,
        [Parameter(Mandatory=$false)]
        [int]
        $Delay=15,
        [Parameter(Mandatory=$false)]
        [string]
        $Username,
        [Parameter(Mandatory=$false)]
        [string]
        $Password
    )

    $Credentials = New-NSCredentials -Credentials $Credentials -Username $Username -Password $Password
    $fqdn = Get-NSEnvironment -Environment $Environment
       
    $BlueServers= (Get-NSServersFromLBServer -Environment $Environment -LB $LBBlue -Credentials $Credentials)
    $GreenServers=(Get-NSServersFromLBServer -Environment $Environment -LB $LBGreen -Credentials $Credentials)

    Write-Host (get-date -Format "yyyy-MM-dd HH:mm:ss.fff") " Blue Servers:" $BlueServers
    Write-Host (get-date -Format "yyyy-MM-dd HH:mm:ss.fff") " Green Servers:" $GreenServers

    $BlueServices =  foreach ($srv in $BlueServers)  { Get-NSServicesFromServer -Environment $Environment -Server $srv -Credentials $Credentials }
    $GreenServices = foreach ($srv in $GreenServers) { Get-NSServicesFromServer -Environment $Environment -Server $srv -Credentials $Credentials }

    Write-Host (get-date -Format "yyyy-MM-dd HH:mm:ss.fff") " Blue Services:" $BlueServices
    Write-Host (get-date -Format "yyyy-MM-dd HH:mm:ss.fff") " Green Services:" $GreenServices

# unbind green services, move green services -> blue LB, drainstop old blue services + wait, unbind blue services, move old blue services -> green LB

# unbind Green services from Green LB
    $contenttype = "application/json"
    $method = "DELETE"
    foreach ($svc in $GreenServices) {
        Write-Host (get-date -Format "yyyy-MM-dd HH:mm:ss.fff") " Unbinding ${svc} from ${LBGreen}"
        $uri = "${fqdn}/nitro/v1/config/lbvserver_service_binding/${LBGreen}?args=servicename:${svc}"
        $Result = Invoke-RestMethod -Method ${method} -Uri ${uri} -ContentType ${contenttype} -Headers @{"X-NITRO-USER"=$Credentials.UserName;"X-NITRO-PASS"=$Credentials.GetNetworkCredential().password;}
    }

# move services from Green LB to Blue LB
    $uri = "${fqdn}/nitro/v1/config/lbvserver_service_binding"
    $contenttype = "application/json"
    $method = "POST"

    foreach ($svc in $GreenServices) {
$json = @"
{
    "params":
    {
        "warning":"YES"
    },
    "lbvserver_service_binding":
    {
        "servicename": "${svc}",
        "weight": "1",
        "name": "${LBBlue}"
    }
}
"@
        Write-Host (get-date -Format "yyyy-MM-dd HH:mm:ss.fff") " Moving ${svc} from ${LBGreen} to ${LBBlue}"
        Invoke-RestMethod -Method ${method} -Uri ${uri} -ContentType ${contenttype} -Headers @{"X-NITRO-USER"=$Credentials.UserName;"X-NITRO-PASS"=$Credentials.GetNetworkCredential().password;} -Body $json
    }

    # Drainstop Old Blue Services
    foreach ($svc in $BlueServices) {
        write-host (get-date -Format "yyyy-MM-dd HH:mm:ss.fff") " Drainstopping ${svc} in ${LBBlue} with ${Delay} Seconds Delay"
        Stop-NSService -Service $svc -Delay $Delay -Environment $Environment -Credentials $Credentials
    }

    Write-Host (get-date -Format "yyyy-MM-dd HH:mm:ss.fff") " Waiting for Drainstop to End"
    foreach ($svc in $BlueServices) {
        Wait-NSService -Service $svc -Environment $Environment -RunOnce $false -Credentials $Credentials -ExpectedState 'OUT OF SERVICE'
    }

    # unbind Old Blue services from Old LB
    $contenttype = "application/json"
    $method = "DELETE"
    foreach ($svc in $BlueServices) {
        Write-Host (get-date -Format "yyyy-MM-dd HH:mm:ss.fff") " Unbinding ${svc} from ${LBBlue}"
        $uri = "${fqdn}/nitro/v1/config/lbvserver_service_binding/${LBBlue}?args=servicename:${svc}"
        $Result = Invoke-RestMethod -Method ${method} -Uri ${uri} -ContentType ${contenttype} -Headers @{"X-NITRO-USER"=$Credentials.UserName;"X-NITRO-PASS"=$Credentials.GetNetworkCredential().password;}
    }

    # move Old services from Blue LB to Green LB
    $uri = "${fqdn}/nitro/v1/config/lbvserver_service_binding"
    $contenttype = "application/json"
    $method = "POST"

    foreach ($svc in $BlueServices) {
$json = @"
{
    "params":
    {
        "warning":"YES"
    },
    "lbvserver_service_binding":
    {
        "servicename": "${svc}",
        "weight": "1",
        "name": "${LBGreen}"
    }
}
"@
        Write-Host (get-date -Format "yyyy-MM-dd HH:mm:ss.fff") " Moving ${svc} from ${LBBlue} to ${LBGreen}"
        Invoke-RestMethod -Method ${method} -Uri ${uri} -ContentType ${contenttype} -Headers @{"X-NITRO-USER"=$Credentials.UserName;"X-NITRO-PASS"=$Credentials.GetNetworkCredential().password;} -Body $json
    }
# Enabling New Green Services
    foreach ($svc in $BlueServices) {
        write-host (get-date -Format "yyyy-MM-dd HH:mm:ss.fff") " Enabling ${svc} in ${LBGreen}"
        Start-NSService -Service $svc -Environment $Environment -Credentials $Credentials
    }
    Write-Host (get-date -Format "yyyy-MM-dd HH:mm:ss.fff") " Waiting for Service to be UP"
    foreach ($svc in $BlueServices) {
        Wait-NSService -Service $svc -Environment $Environment -RunOnce $false -Credentials $Credentials -ExpectedState UP
    }
}

function Start-NSServerInServiceGroup {
    Param(
        [Parameter(Mandatory=$true)]
        [string]
        $ServiceGroup,
        [Parameter(Mandatory=$true)]
        [string]
        $ServerName,
        [Parameter(Mandatory=$true)]
        [int]
        $Port,
        [Parameter(Mandatory=$true)]
        [ValidateSet("QA", "PROD","QA-AZ", "PROD-AZ")]
        [string]
        $Environment,
        [Parameter(Mandatory=$false)]
        [PSCredential]
        $Credentials,
        [Parameter(Mandatory=$false)]
        [string]
        $Username,
        [Parameter(Mandatory=$false)]
        [string]
        $Password
    )

    $Credentials = New-NSCredentials -Credentials $Credentials -Username $Username -Password $Password
    $fqdn = Get-NSEnvironment -Environment $Environment

    $contenttype = "application/json"
    $method = "POST"

    $uri = "${fqdn}/nitro/v1/config/servicegroup?action=enable"
$json = @"
{
    "params":
    {
        "action": "enable",
        "warning": "YES"
    },
   "servicegroup": 
    {
        "servicegroupname":"${ServiceGroup}",
        "servername":"${ServerName}",
        "port":${port}
    }
}
"@
    Invoke-RestMethod -Method ${method} -Uri ${uri} -ContentType ${contenttype} -Headers @{"X-NITRO-USER"=$Credentials.UserName;"X-NITRO-PASS"=$Credentials.GetNetworkCredential().password;} -Body $json
}

function Stop-NSServerInServiceGroup {
    Param(
        [Parameter(Mandatory=$true)]
        [string]
        $ServiceGroup,
        [Parameter(Mandatory=$true)]
        [string]
        $ServerName,
        [Parameter(Mandatory=$true)]
        [int]
        $Port,
        [Parameter(Mandatory=$false)]
        [int]
        $Delay=5,
        [Parameter(Mandatory=$true)]
        [ValidateSet("QA", "PROD","QA-AZ", "PROD-AZ")]
        [string]
        $Environment,
        [Parameter(Mandatory=$false)]
        [PSCredential]
        $Credentials,
        [Parameter(Mandatory=$false)]
        [string]
        $Username,
        [Parameter(Mandatory=$false)]
        [string]
        $Password
    )

    $Credentials = New-NSCredentials -Credentials $Credentials -Username $Username -Password $Password
    $fqdn = Get-NSEnvironment -Environment $Environment

    $contenttype = "application/json"
    $method = "POST"

    $uri = "${fqdn}/nitro/v1/config/servicegroup?action=disable"
$json = @"
{
    "params": 
    {
        "warning":"YES",
        "action":"disable"
    },
    "servicegroup": 
    {
        "servicegroupname":"${ServiceGroup}",
        "servername":"${ServerName}",
        "port":${port},
        "delay":"${delay}",
        "graceful":"NO"
    }
}
"@
    Invoke-RestMethod -Method ${method} -Uri ${uri} -ContentType ${contenttype} -Headers @{"X-NITRO-USER"=$Credentials.UserName;"X-NITRO-PASS"=$Credentials.GetNetworkCredential().password;} -Body $json
}

function Get-NSLBServerFromServiceGroup {
    Param(
        [Parameter(Mandatory=$true)]
        [ValidateSet("QA", "PROD","QA-AZ", "PROD-AZ")]
        [string]
        $Environment,
        [Parameter(Mandatory=$true)]
        [string]
        $ServiceGroup,
        [Parameter(Mandatory=$false)]
        [PSCredential]
        $Credentials,
        [Parameter(Mandatory=$false)]
        [string]
        $Username,
        [Parameter(Mandatory=$false)]
        [string]
        $Password
    )

    $Credentials = New-NSCredentials -Credentials $Credentials -Username $Username -Password $Password
    $fqdn = Get-NSEnvironment -Environment $Environment

    $contenttype = "application/vnd.com.citrix.netscaler.service+json"
    $method = "GET"
    $uri = "${fqdn}/nitro/v1/config/servicegroupbindings/${ServiceGroup}"

    $SvrObject=Invoke-RestMethod -Method ${method} -Uri ${uri} -ContentType ${contenttype} -Headers @{"X-NITRO-USER"=$Credentials.UserName;"X-NITRO-PASS"=$Credentials.GetNetworkCredential().password;}
    foreach ($lb in $SvrObject.servicegroupbindings) { $lb.vservername }
}

function Get-NSServersFromServiceGroup {
    Param(
        [Parameter(Mandatory=$true)]
        [ValidateSet("QA", "PROD","QA-AZ", "PROD-AZ")]
        [string]
        $Environment,
        [Parameter(Mandatory=$true)]
        [string]
        $ServiceGroup,
        [Parameter(Mandatory=$false)]
        [PSCredential]
        $Credentials,
        [Parameter(Mandatory=$false)]
        [string]
        $Username,
        [Parameter(Mandatory=$false)]
        [string]
        $Password
    )

    $Credentials = New-NSCredentials -Credentials $Credentials -Username $Username -Password $Password
    $fqdn = Get-NSEnvironment -Environment $Environment

    $contenttype = "application/vnd.com.citrix.netscaler.service+json"
    $method = "GET"
    $uri = "${fqdn}/nitro/v1/config/servicegroup_servicegroupmember_binding/${ServiceGroup}"

    $SvrObject=Invoke-RestMethod -Method ${method} -Uri ${uri} -ContentType ${contenttype} -Headers @{"X-NITRO-USER"=$Credentials.UserName;"X-NITRO-PASS"=$Credentials.GetNetworkCredential().password;}
    foreach ($srv in $svrobject.servicegroup_servicegroupmember_binding) {$srv.servername + ',' + $srv.port}
}

function Get-NSServiceGroupsFromServer {
    Param(
        [Parameter(Mandatory=$true)]
        [ValidateSet("QA", "PROD","QA-AZ", "PROD-AZ")]
        [string]
        $Environment,
        [Parameter(Mandatory=$true)]
        [string]
        $Server,
        [Parameter(Mandatory=$false)]
        [PSCredential]
        $Credentials,
        [Parameter(Mandatory=$false)]
        [string]
        $Username,
        [Parameter(Mandatory=$false)]
        [string]
        $Password
    )

    $Credentials = New-NSCredentials -Credentials $Credentials -Username $Username -Password $Password
    $fqdn = Get-NSEnvironment -Environment $Environment

    $contenttype = "application/vnd.com.citrix.netscaler.service+json"
    $method = "GET"

    $uri = "${fqdn}/nitro/v1/config/server_binding/${Server}"

    $SvrObject=Invoke-RestMethod -Method ${method} -Uri ${uri} -ContentType ${contenttype} -Headers @{"X-NITRO-USER"=$Credentials.UserName;"X-NITRO-PASS"=$Credentials.GetNetworkCredential().password;}

    foreach ($svc in ($SvrObject.server_binding).server_servicegroup_binding) { $svc.servicegroupname }
}

function Get-NSServiceGroupFromLBServer {
    Param(
        [Parameter(Mandatory=$true)]
        [ValidateSet("QA", "PROD","QA-AZ", "PROD-AZ")]
        [string]
        $Environment,
        [Parameter(Mandatory=$true)]
        [string]
        $Server,
        [Parameter(Mandatory=$false)]
        [PSCredential]
        $Credentials,
        [Parameter(Mandatory=$false)]
        [string]
        $Username,
        [Parameter(Mandatory=$false)]
        [string]
        $Password
    )

    $Credentials = New-NSCredentials -Credentials $Credentials -Username $Username -Password $Password
    $fqdn = Get-NSEnvironment -Environment $Environment

    $contenttype = "application/vnd.com.citrix.netscaler.service+json"
    $method = "GET"
    $uri = "${fqdn}/nitro/v1/config/lbvserver_servicegroup_binding/${Server}"

    $SvrObject=Invoke-RestMethod -Method ${method} -Uri ${uri} -ContentType ${contenttype} -Headers @{"X-NITRO-USER"=$Credentials.UserName;"X-NITRO-PASS"=$Credentials.GetNetworkCredential().password;}
    $SvrObject.lbvserver_servicegroup_binding.servicegroupname
}
