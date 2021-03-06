# http://sirsql.net/blog/2012/7/5/configuring-dtc-security-in-a-cluster-with-powershell.html

<#

.SYNOPSIS

   Configures MSDTC on a cluster

.DESCRIPTION

   This configures a basic networked config for MSDTC for clustered SQL Server instances.

   Uncomment the transaction manager security setting and enter the correct ServiceName that can be found in FC manager

.PARAMETER <paramName>

   NONE

.EXAMPLE

   NONE

#>

 

$ServiceName = "SQL Server (SOX2)"

 

#--What MSDTC Transaction Manager Security setting is requested? (uncomment one)

$TranManSec = "Mutual" #Mutual Authentication Required

#$TranManSec = "Incoming" #Incoming Called Authentication Required

#$TranManSec = "None" #No Authentication Required

 

 

 

 

#Grab a list of cluster groups

$GroupPath = "HKLM:\Cluster\Groups"

$GroupList = dir $GroupPath

 

#Iterate through the groups to find the one matching the service name

foreach ($Group in $GroupList)

{

    $GroupChildPath = $Group.PSPath

    if ((Get-ItemProperty -path $GroupChildPath -name Name).Name -eq $ServiceName)

    {

        #we got a match! Now grab a list of the groups in this service

        $ReferencedResources = (Get-ItemProperty -path $GroupChildPath -name Contains).Contains

        foreach ($Resource in $ReferencedResources)

        {

            #Query each of the resources for their type and work with MSDTC

            $ResourcePath = "HKLM:\Cluster\Resources\$Resource"

            if ((Get-ItemProperty -path $ResourcePath).Type -eq "Distributed Transaction Coordinator")

            {

                #We found MSDTC resource for that service group, let's configure it

                $SecurityPath = "$ResourcePath\MSDTCPRIVATE\MSDTC\Security"

                Set-ItemProperty -path $SecurityPath -name "NetworkDtcAccess" -value 1

                Set-ItemProperty -path $SecurityPath -name "NetworkDtcAccessClients" -value 0

                Set-ItemProperty -path $SecurityPath -name "NetworkDtcAccessTransactions" -value 0

                Set-ItemProperty -path $SecurityPath -name "NetworkDtcAccessInbound" -value 1

                Set-ItemProperty -path $SecurityPath -name "NetworkDtcAccessOutbound" -value 1

                Set-ItemProperty -path $SecurityPath -name "LuTransactions" -value 1

 

                #Now configure the authentication method for MSDTC (defaulting to Mutual Auth as it's most secure)

                $SecurityPath = "$ResourcePath\MSDTCPRIVATE\MSDTC"

                if ($TranManSec -eq "None")

                {

                    Set-ItemProperty -path $MSDTCPath -name "TurnOffRpcSecurity" -value 1

                    Set-ItemProperty -path $MSDTCPath -name "AllowOnlySecureRpcCalls" -value 0

                    Set-ItemProperty -path $MSDTCPath -name "FallbackToUnsecureRPCIfNecessary" -value 0

                }

 

                elseif ($TranManSec -eq "Incoming")

                {

                    Set-ItemProperty -path $MSDTCPath -name "TurnOffRpcSecurity" -value 0

                    Set-ItemProperty -path $MSDTCPath -name "AllowOnlySecureRpcCalls" -value 0

                    Set-ItemProperty -path $MSDTCPath -name "FallbackToUnsecureRPCIfNecessary" -value 1

                }

 

                else 

                {

                    Set-ItemProperty -path $MSDTCPath -name "TurnOffRpcSecurity" -value 0

                    Set-ItemProperty -path $MSDTCPath -name "AllowOnlySecureRpcCalls" -value 1

                    Set-ItemProperty -path $MSDTCPath -name "FallbackToUnsecureRPCIfNecessary" -value 0

                } 

 

            }

        }

    }

}
