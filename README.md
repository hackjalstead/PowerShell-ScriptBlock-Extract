Extract all or specific Script Blocks from the PowerShell Operational EVTX.

To extract all Script Blocks use -      .\scriptBlockExtract4.ps1 -path "path\to\dir" 
To specific Script Block IDs use -      .\scriptBlockExtract4.ps1 -path "path\to\dir" -ScriptBlockID "script-block-id"
Log file ouput may be quarantined or empty if Windows Defender detects malware. Recommended to disable it while running. 
