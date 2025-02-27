# Set variables
$grafanaUrl = "http://localhost:3000"
$apiToken = $env:GRAFANA_API_TOKEN  # Get token from environment variable
$headers = @{
    "Authorization" = "Bearer $apiToken"
    "Content-Type"  = "application/json"
}
$backupPath = "C:\work\grafanaConfig1"

# Ensure backup directory exists
if (!(Test-Path -Path $backupPath)) {
    New-Item -ItemType Directory -Path $backupPath | Out-Null
}


# Function to save API response to a file
function Save-ApiData {
    param (
        [string]$url,
        [string]$filePath
    )
    try {
        $response = Invoke-RestMethod -Uri $url -Headers $headers -Method Get
        $response | ConvertTo-Json -Depth 10 | Out-File -Encoding utf8 $filePath
        Write-Host "Saved: $filePath"
    }
    catch {
        Write-Host "Error fetching: $url"
    }
}

Write-Host "Starting Grafana Configuration Backup..."

# Backup Dashboards
$dashboards = Invoke-RestMethod -Uri "$grafanaUrl/api/search?query=" -Headers $headers -Method Get
foreach ($dashboard in $dashboards) {
    $uid = $dashboard.uid
    if ($uid) {
        $dashboardData = Invoke-RestMethod -Uri "$grafanaUrl/api/dashboards/uid/$uid" -Headers $headers -Method Get
        $dashboardData | ConvertTo-Json -Depth 10 | Out-File -Encoding utf8 "$backupPath/dashboards_$uid.json"
        Write-Host "Saved: dashboards_$uid.json"
    }
}

# Backup Data Sources
Save-ApiData "$grafanaUrl/api/datasources" "$backupPath/datasources.json"

# Backup Alerting Rules
Save-ApiData "$grafanaUrl/api/alerting/provisioning/alert-rules" "$backupPath/alert_rules.json"

# Backup Users & Permissions
Save-ApiData "$grafanaUrl/api/users" "$backupPath/users.json"
Save-ApiData "$grafanaUrl/api/org/users" "$backupPath/org_users.json"

# Backup Organizations
Save-ApiData "$grafanaUrl/api/orgs" "$backupPath/orgs.json"

# Backup Folder Permissions
$folders = Invoke-RestMethod -Uri "$grafanaUrl/api/folders" -Headers $headers -Method Get
foreach ($folder in $folders) {
    $folderId = $folder.uid
    Save-ApiData "$grafanaUrl/api/folders/$folderId/permissions" "$backupPath/folder_permissions_$folderId.json"
}

# Backup Annotations
Save-ApiData "$grafanaUrl/api/annotations" "$backupPath/annotations.json"

# Backup Preferences
Save-ApiData "$grafanaUrl/api/org/preferences" "$backupPath/preferences.json"

# Backup Plugin Configurations
Save-ApiData "$grafanaUrl/api/plugins" "$backupPath/plugins.json"

# Backup Notification Channels
Save-ApiData "$grafanaUrl/api/alert-notifications" "$backupPath/alert_notifications.json"

Write-Host "Grafana backup completed."

# Git automation
cd $backupPath
git add .
$commitMessage = "Grafana backup - $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
git commit -m $commitMessage
git push origin main

Write-Host "Backup pushed to GitHub."
#$env:GRAFANA_API_TOKEN = "glsa_aguEDgEIZTlEY3BsgU12ytYCLer5hltV_ddd2a67b"
#powershell -ExecutionPolicy Bypass -File C:\work\grafanaConfig1\grafana_backup.ps1
