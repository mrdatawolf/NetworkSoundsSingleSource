# Function to load .env file
function Load-EnvFile {
    param (
        [string]$envFilePath
    )
    Get-Content $envFilePath | ForEach-Object {
        if ($_ -match "^\s*([^#][^=]+)=(.*)\s*$") {
            $name = $matches[1].Trim()
            $value = $matches[2].Trim()
            [System.Environment]::SetEnvironmentVariable($name, $value)
        }
    }
}

# Load the .env file
$scriptPath = $MyInvocation.MyCommand.Path
$scriptDir = Split-Path -Path $scriptPath -Parent
$envFilePath = Join-Path -Path $scriptDir -ChildPath ".env"
Load-EnvFile -envFilePath $envFilePath

# Function to play sound using System.Media.SoundPlayer in a background job
function Play-Sound {
    param (
        [string]$soundFileName
    )
    Start-Job -ScriptBlock {
        param ($soundFilePath)
        $soundPlayer = New-Object System.Media.SoundPlayer
        $soundPlayer.SoundLocation = $soundFilePath
        $soundPlayer.PlaySync()
    } -ArgumentList (Join-Path -Path $env:SOUND_LOCATION -ChildPath $soundFileName)
}

# Function to get primary network adapter
function Get-PrimaryNetworkAdapter {
    $adapter = Get-NetAdapter | Where-Object { $_.Status -eq "Up" } | Sort-Object -Property LinkSpeed -Descending | Select-Object -First 1
    return $adapter.Name
}

# Function to get network statistics
function Get-NetworkStats {
    param (
        [string]$adapterName
    )
    $netStats = Get-NetAdapterStatistics -Name $adapterName
    return $netStats
}

# Function to calculate bandwidth usage percentage
function Get-BandwidthUsagePercentage {
    param (
        [int64]$receivedBytes,
        [int64]$maxBandwidthBytes
    )
    return ($receivedBytes / $maxBandwidthBytes) * 100
}

# Define the maximum bandwidth in bytes (example: 1 Gbps)
$maxBandwidthBytes = 125000000

# Determine the network adapter to use
$primaryAdapter = if ($env:OVERRIDE_ADAPTER) { $env:OVERRIDE_ADAPTER } else { Get-PrimaryNetworkAdapter }

# Display the network adapter being used
Write-Host "Using network adapter: $primaryAdapter"

# Initialize previous received bytes
$previousReceivedBytes = (Get-NetworkStats -adapterName $primaryAdapter).ReceivedBytes

# Main loop to monitor network traffic and play sound based on conditions
while ($true) {
    Start-Sleep -Seconds 10 # Check every 10 seconds

    $stats = Get-NetworkStats -adapterName $primaryAdapter
    $currentReceivedBytes = $stats.ReceivedBytes
    $receivedBytesDifference = $currentReceivedBytes - $previousReceivedBytes
    $percentageUsed = Get-BandwidthUsagePercentage -receivedBytes $receivedBytesDifference -maxBandwidthBytes $maxBandwidthBytes

    # Update previous received bytes
    $previousReceivedBytes = $currentReceivedBytes

    # Debugging output
    Write-Host "Received bytes difference: $receivedBytesDifference"
    Write-Host "Max bandwidth bytes: $maxBandwidthBytes"
    Write-Host "Bandwidth usage percentage: $percentageUsed"

    if ($percentageUsed -ge 99) {
        Play-Sound -soundFileName $env:SOUND_100
    }
    if ($percentageUsed -ge 90) {
        Play-Sound -soundFileName $env:SOUND_90
    }
    if ($percentageUsed -ge 80) {
        Play-Sound -soundFileName $env:SOUND_80
    }
    if ($percentageUsed -ge 70) {
        Play-Sound -soundFileName $env:SOUND_70
    }
    if ($percentageUsed -ge 60) {
        Play-Sound -soundFileName $env:SOUND_60
    }
    if ($percentageUsed -ge 50) {
        Play-Sound -soundFileName $env:SOUND_50
    }
    if ($percentageUsed -ge 40) {
        Play-Sound -soundFileName $env:SOUND_40
    }
    if ($percentageUsed -ge 30) {
        Play-Sound -soundFileName $env:SOUND_30
    }
    if ($percentageUsed -ge 20) {
        Play-Sound -soundFileName $env:SOUND_20
    }
    Play-Sound -soundFileName $env:SOUND_BASE
}