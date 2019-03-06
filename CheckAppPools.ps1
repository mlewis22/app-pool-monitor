#
# the following is a simple script which loops over app pools in IIS.
# if one is found to be stopped it starts it again.
#
# Author: Matthew Lewis
# Date: 03/06/2019
#


$Servers = hostname
$logok = $false # set to $true if you want to have a log for app pool is ok.

Write-Host "Starting on : " $Servers

Invoke-Command -ComputerName $Servers {

    ## Get IIS details
    Import-Module -Name WebAdministration
    $Websites  = Get-Website | Where-Object serverAutoStart -eq $true

    ## continous loop
    while($true) {
        $date = Get-Date -Format g
        
        ## loop over websites
        foreach ($Website in $Websites) {

            ## check app pools
            switch ($Website) {
                {(Get-WebAppPoolState -Name $_.applicationPool).Value -eq 'Stopped'} {
                    
                    ## start the app pool
                    Start-WebAppPool -Name $_.applicationPool

                    ## write log to windows event
                    $message = $_.applicationPool + ": App Pool RESTARTING - " + $date
                    New-EventLog –LogName Application –Source "App Pool Monitor"
                    Write-EventLog -LogName Application -Source "App Pool Monitor" -EventID 3001 -EntryType Warning -Message $message  -Category 1 -RawData 10,20
                    Write-Host $message
                }
                {(Get-WebAppPoolState -Name $_.applicationPool).Value -eq 'Started'} {
                    if ($logok) {
                        $message = $_.applicationPool + ": App Pool Ok - " + $date 
                        Write-Host $message
                    }
                    
                }
            }
        }
        # delay
        Start-Sleep 15 
    }
}
