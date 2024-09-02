# Function to pause for a specific duration or indefinitely based on success
function Pause-Script {
    param (
        [bool]$success
    )

    if ($success) {
        Write-Host "Script completed successfully. Exiting in 5 seconds..." -ForegroundColor Green
        Start-Sleep -Seconds 5
    } else {
        Write-Host "An error occurred. Press any key to exit..." -ForegroundColor Red
        $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") > $null
    }
}

# Check if pip is installed
$pipVersion = & python -m pip --version 2>&1
if ($pipVersion -match "not recognized" -or $pipVersion -eq $null) {
    Write-Host "Pip is not installed. Please install pip first." -ForegroundColor Red
    Pause-Script -success $false
    exit
}

# Install required packages
Write-Host "Installing required Python packages..." -ForegroundColor Cyan
try {
    & pip install -r requirements.txt
} catch {
    Write-Host "Failed to install required packages. Please check requirements.txt." -ForegroundColor Red
    Pause-Script -success $false
    exit
}

# Run the Python script
Write-Host "Running change_logo.py..." -ForegroundColor Cyan
try {
    & python change_logo.py
} catch {
    Write-Host "Failed to execute change_logo.py. Please check the script for errors." -ForegroundColor Red
    Pause-Script -success $false
    exit
}

# Pause for 5 seconds if successful
Pause-Script -success $true
