# To run -
#   
#   To extract all Script Blocks use -      .\scriptBlockExtract4.ps1 -path "path\to\dir" 
#   To specific Script Block IDs use -      .\scriptBlockExtract4.ps1 -path "path\to\dir" -ScriptBlockID "script-block-id"
#   Log file ouput may be quarantined or empty if Windows Defender detects malware. Recommended to disable it while running. 

param (
    [Parameter(Mandatory = $true)]
    [string]$path,

    [Parameter(Mandatory = $false)]
    [string]$ScriptBlockID
)

$LogFile = "PowerShell_ScriptBlocks_$(Get-Date -Format 'yyyy-MM-ddTHHmmssZ').log"

Write-Host "Searching for PowerShell Operational EVTX in: $path" -ForegroundColor Cyan

$evtxFiles = Get-ChildItem -Path $path -Filter *.evtx -Recurse | Where-Object {
    $_.BaseName -eq "Microsoft-Windows-PowerShell%4Operational" #adjust or add PS Operational here if its been renamed at src.
}

if (-not $evtxFiles) {
    Write-Warning "No PowerShell Operational EVTX found in $path"
    exit
}

Write-Host "Found $($evtxFiles.Count) EVTX" -ForegroundColor Green
$found = 0

foreach ($file in $evtxFiles) {
    $EvtxFile = $file.FullName
    Write-Host "`nExtracting Script Blocks from $EvtxFile..." -ForegroundColor Cyan
    if ($ScriptBlockID) {
        Write-Host "Filtering for Script Block ID: $ScriptBlockID" -ForegroundColor Cyan
    }

    try {
        $events = Get-WinEvent -Path $EvtxFile -FilterXPath "*[System[(EventID=4104)]]" -ErrorAction Stop
        if ($found -eq 0) {
            "Script Block extract started at $(Get-Date)" | Out-File -FilePath $LogFile -Encoding utf8
        }

        foreach ($event in $events) {
            $message = $event.Message

            $scriptID = ""
            if ($message -match "ScriptBlock ID:\s+([^\r\n]+)") {
                $scriptID = $matches[1]
            }

            if ($ScriptBlockID -and ($scriptID -ne $ScriptBlockID)) {
                continue
            }

            Write-Host "`n--- SCRIPT BLOCK FOUND ---" -ForegroundColor Yellow
            if ($scriptID) {
                Write-Host "Script Block ID: $scriptID"
            } else {
                Write-Host "Script Block ID: (Not found)"
            }
            Write-Host "Time Stamp: $($event.TimeCreated)"
            Write-Host "Message:"
            Write-Host "$message"

            Add-Content -Path $LogFile -Value @"
======================================================== SCRIPT BLOCK ========================================================
File: $EvtxFile
Script Block ID: $scriptID
Time Stamp: $($event.TimeCreated)
Message:
$message

"@

            $found++
        }
    }
    catch {
        Write-Warning "Failed to read events from $EvtxFile. $_"
    }
}
Write-Host "`nTotal Script Blocks found: $found" -ForegroundColor Green
Write-Host "Results saved to: $LogFile" -ForegroundColor Green