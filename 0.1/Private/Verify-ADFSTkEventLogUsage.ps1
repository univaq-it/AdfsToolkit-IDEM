function Verify-ADFSTkEventLogUsage 
{

    # We ingest the eventLogging settings from the config file and set things up to accept eventlog traffic 
    $EventLogEnabled=0

   
    try {

        if ( $Settings.configuration.Logging -ne $null -and $Settings.configuration.Logging.HasAttribute('useEventLog') -and $Settings.configuration.Logging.useEventLog.ToLower() -eq 'true' )
        {

            $MyLogName=$Settings.configuration.logging.LogName
            $MySource =$Settings.configuration.logging.Source

                # We know we should log to the event log by the time we are here.

                # Both LogName and MySource need to be non empty

                if ( [System.Diagnostics.EventLog]::Exists($MyLogName) -and [System.Diagnostics.EventLog]::SourceExists($MySource) )
                    {
                        
                        # This is good, both log and source exist, and logging is activatated
                    Write-EventLog -LogName $MyLogName -Source $MySource -EventId 1 -Message "EventLog Being Used on this run"
                    $EventLogEnabled=1

                    }else 
                    {
                        # eventlog does not exist yet, create when sufficient info is provided
                       
                        if ($MyLogName -and $MySource )
                        {
                            #both the logName and Source need to exist before we'll create them.

                            #First, we delete the eventlog source so we can assign it to the right LogName destination
                            Remove-EventLog -Source $MySource -ErrorAction SilentlyContinue

                            # Second, we now issue the appropriate Association to the LogName

                            # If the log does not exist, New-EventLog creates the log and uses this value 
                            # for the Log and LogDisplayName properties of the new event log. 
                            # If the log exists, New-EventLog registers a new source for the event log.
                            # https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.management/new-eventlog?view=powershell-5.1 
                            
                            New-EventLog -LogName $MyLogName -Source $MySource
                            Limit-EventLog -OverflowAction OverWriteAsNeeded -LogName $MyLogName
                            Write-EventLog -LogName $MyLogName -Source $MySource -EventId 1 -Message "ADFSToolkit EventLog Created"
                            $EventLogEnabled=1

                        }else {

                            Write-Error "EventLog creation failure: config has no LogName or Source"
                            $EventLogEnabled=0
                            
                            }

                    } # end eventlog creation step

         }
            else {
                     # EventLogging is not used, we signal false  
                  
                    $EventLogEnabled=0
                 }        

                
    }
        Catch
        {
            Throw $_
        }
    
 # pass the true/false for eventlog to invoker
                $EventLogEnabled
}