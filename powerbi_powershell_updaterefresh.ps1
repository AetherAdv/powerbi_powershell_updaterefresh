# Connect to Power BI Service Account

Connect-PowerBIServiceAccount

 

# Retrieve all workspaces

$workspaces = Get-PowerBIWorkspace -All

 

 

# Retrieve target workspace

#$workspaces = Get-PowerBIWorkspace -id "####"

 

# Loop through each workspace

foreach ($workspace in $workspaces) {

 

    # Get reports with names starting with "AETHER" in the current workspace

    $Reportlist = Get-PowerBIReport -WorkspaceId $workspace.Id | Where-Object { $_.Name -like 'AETHER*' }

 

    # Check if any matching reports exist

    if ($Reportlist) {

        foreach ($Report in $Reportlist) {

 

            # Ensure the report has an associated DatasetId (required for refresh scheduling)

            if ($Report.DatasetId) {

                $ReportName = $Report.Name

                $WorkspaceId = $workspace.Id

                $ReportId = $Report.Id

                $DatasetId = $Report.DatasetId

 

                Write-Host "Updating refresh schedule for: $ReportName in Workspace: $WorkspaceId"

 

                # Construct the API URL for updating the refresh schedule

                $ApiUrl = "https://api.powerbi.com/v1.0/myorg/groups/$WorkspaceId/datasets/$DatasetId/refreshSchedule"

 

                # Define the refresh schedule settings

                $ApiRequestBody = @{

                    value = @{

                        days            = @("Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday")  # Runs daily

                        times           = @("16:00")  # Refresh time in UTC

                        notifyOption    = "MailOnFailure"  # Notify only on failure

                        localTimeZoneId = "UTC"  # Time zone for the refresh schedule

                        enabled         = $true  # Ensure the schedule is enabled

                    }

                } | ConvertTo-Json -Depth 3  # Convert to JSON format

 

                try {

                    # Send API request to update the refresh schedule

                    Invoke-PowerBIRestMethod -Url $ApiUrl -Method Patch -Body $ApiRequestBody -Verbose

                    Write-Host "Successfully updated data refresh schedule for: $ReportName" -ForegroundColor Green

                } catch {

                    # Handle any errors during the API request

                    Write-Host "Failed to update refresh schedule for: $ReportName" -ForegroundColor Red

                    Write-Host "Error: $_" -ForegroundColor Yellow

                }

            } else {

                # Skip reports without a DatasetId (they cannot have a refresh schedule)

                Write-Host "Skipping report '$ReportName' as it has no associated DatasetId." -ForegroundColor Yellow

            }

        }

    }

}