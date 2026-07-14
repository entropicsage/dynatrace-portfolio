# Windows Server Administration Notes

These notes cover common Windows Server administration tasks that complement Linux and Kubernetes skills in a Dynatrace-heavy environment.

A well-rounded candidate for Dynatrace + mixed OS administration roles should be comfortable on both Linux and Windows.

## Disk Management

```powershell
# View disk usage
Get-PSDrive -PSProvider FileSystem

# Check specific drive
Get-Volume -DriveLetter C

# Extend volume (after growing in hypervisor/cloud)
# Use Disk Management GUI or:
Resize-Partition -DriveLetter C -Size (Get-Partition -DriveLetter C).Size + 10GB   # example

# Find large directories (PowerShell)
Get-ChildItem -Path C:\ -Recurse -ErrorAction SilentlyContinue |
  Where-Object { $_.PSIsContainer } |
  ForEach-Object {
    $size = (Get-ChildItem $_.FullName -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
    [PSCustomObject]@{ Path = $_.FullName; SizeGB = [math]::Round($size / 1GB, 2) }
  } | Sort-Object SizeGB -Descending | Select-Object -First 10
```

## Services and Processes

```powershell
# List services
Get-Service | Where-Object {$_.Status -eq "Running"}

# Restart a service
Restart-Service -Name "W3SVC" -Force

# Top processes by memory/CPU
Get-Process | Sort-Object WorkingSet -Descending | Select-Object -First 10 Name, Id, CPU, WorkingSet

# Event logs (critical for Dynatrace correlation)
Get-WinEvent -LogName System -MaxEvents 50 | Where-Object {$_.LevelDisplayName -eq "Error"}
Get-WinEvent -LogName Application -MaxEvents 20
```

## Performance & Monitoring

```powershell
# Quick performance snapshot
Get-Counter '\Processor(_Total)\% Processor Time', '\Memory\Available MBytes', '\LogicalDisk(_Total)\% Free Space'

# Resource monitor style
perfmon.exe   # GUI

# Check for high disk queue
Get-Counter '\PhysicalDisk(_Total)\Current Disk Queue Length'
```

## Remote Administration & PowerShell Remoting

```powershell
# Enable remoting (run as admin)
Enable-PSRemoting -Force

# Connect to remote server
Enter-PSSession -ComputerName SERVER01

# Run command remotely
Invoke-Command -ComputerName SERVER01 -ScriptBlock { Get-Service | Where Status -eq 'Stopped' }
```

## Common Dynatrace + Windows Scenarios

- High disk on Windows host → Use Get-Volume + directory size script above
- Service crashes → Check Application/System event logs
- IIS / .NET apps → Look at w3wp.exe processes and recycle logs
- OneAgent not reporting → Check OneAgent service status and logs under C:\ProgramData\dynatrace

## Recommended Tools

- PowerShell 7+
- Sysinternals (Process Explorer, Disk2vhd, etc.)
- Windows Admin Center (web-based management)
- Event Viewer + PowerShell filtering for fast correlation with Dynatrace problems

These commands and patterns pair well with the Linux scripts in this directory when managing hybrid environments.