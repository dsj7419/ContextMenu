#Requires -Version 5.1

<#
.SYNOPSIS
    Generates a custom Windows context menu registry file based on installed tools.

.DESCRIPTION
    Auto-detects VS Code, Git Bash, PowerShell 7, WSL, and Windows Terminal,
    then creates a .reg file with properly escaped paths. Also generates an
    undo .reg file to restore Windows defaults.

.EXAMPLE
    .\Generate-ContextMenu.ps1
    Generates ContextMenu-Custom.reg and ContextMenu-Undo.reg in the current directory.

.EXAMPLE
    .\Generate-ContextMenu.ps1 -OutputPath "C:\Temp"
    Generates registry files in the specified directory.
#>

[CmdletBinding()]
param(
    [Parameter()]
    [string]$OutputPath = ""
)

# Handle empty PSScriptRoot (happens when launched via powershell -File)
if ([string]::IsNullOrWhiteSpace($OutputPath)) {
    $OutputPath = if ($PSScriptRoot) { $PSScriptRoot } else { Get-Location | Select-Object -ExpandProperty Path }
}

#region Helper Functions

function Find-ExecutablePath {
    param(
        [string[]]$PossiblePaths,
        [string]$ExecutableName
    )
    
    foreach ($path in $PossiblePaths) {
        $expandedPath = [Environment]::ExpandEnvironmentVariables($path)
        if (Test-Path $expandedPath) {
            return $expandedPath
        }
    }
    
    # Fallback: check if it's in PATH
    $inPath = Get-Command $ExecutableName -ErrorAction SilentlyContinue
    if ($inPath) {
        return $inPath.Source
    }
    
    return $null
}

function ConvertTo-RegPath {
    param([string]$Path)
    
    # Escape backslashes for registry format
    return $Path -replace '\\', '\\\\'
}

function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Color = "White"
    )
    Write-Host $Message -ForegroundColor $Color
}

#endregion

#region Tool Detection

Write-ColorOutput "`n=== Windows Context Menu Generator ===" "Cyan"
Write-ColorOutput "Detecting installed tools...`n" "Yellow"

$tools = @{
    VSCode = @{
        Name = "Visual Studio Code"
        Paths = @(
            "${env:ProgramFiles}\Microsoft VS Code\Code.exe",
            "${env:LOCALAPPDATA}\Programs\Microsoft VS Code\Code.exe"
        )
        Executable = "Code.exe"
        Found = $false
        Path = $null
    }
    GitBash = @{
        Name = "Git Bash"
        Paths = @(
            "${env:ProgramFiles}\Git\git-bash.exe",
            "${env:ProgramFiles(x86)}\Git\git-bash.exe",
            "${env:LOCALAPPDATA}\Programs\Git\git-bash.exe"
        )
        Executable = "git-bash.exe"
        Found = $false
        Path = $null
    }
    PowerShell7 = @{
        Name = "PowerShell 7"
        Paths = @(
            "${env:ProgramFiles}\PowerShell\7\pwsh.exe",
            "${env:LOCALAPPDATA}\Microsoft\PowerShell\7\pwsh.exe"
        )
        Executable = "pwsh.exe"
        Found = $false
        Path = $null
    }
    WSL = @{
        Name = "Windows Subsystem for Linux"
        Paths = @("${env:SystemRoot}\System32\wsl.exe")
        Executable = "wsl.exe"
        Found = $false
        Path = $null
    }
    WindowsTerminal = @{
        Name = "Windows Terminal"
        Paths = @("wt.exe")  # Always in PATH if installed
        Executable = "wt.exe"
        Found = $false
        Path = $null
    }
}

# Detect each tool
foreach ($key in $tools.Keys) {
    $tool = $tools[$key]
    $foundPath = Find-ExecutablePath -PossiblePaths $tool.Paths -ExecutableName $tool.Executable
    
    if ($foundPath) {
        $tool.Found = $true
        $tool.Path = $foundPath
        Write-ColorOutput "  ✓ $($tool.Name): $foundPath" "Green"
    } else {
        Write-ColorOutput "  ✗ $($tool.Name): Not found" "DarkGray"
    }
}

# Windows Terminal is required
if (-not $tools.WindowsTerminal.Found) {
    Write-ColorOutput "`n⚠ Windows Terminal is required for this context menu. Install it from the Microsoft Store." "Red"
    exit 1
}

#endregion

#region Registry Content Generation

Write-ColorOutput "`nGenerating registry entries..." "Yellow"

$regContent = @"
Windows Registry Editor Version 5.00

; ============================================
; CUSTOM WINDOWS 11 CONTEXT MENU
; Generated: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
; ============================================
; This file was auto-generated. Do not edit manually.
; Run Generate-ContextMenu.ps1 again to regenerate.

; Windows Terminal - Primary Quick Access
[HKEY_CLASSES_ROOT\Directory\shell\00Terminal]
"Position"="Top"
"MUIVerb"="Terminal Here"
"Icon"="wt.exe"
[HKEY_CLASSES_ROOT\Directory\shell\00Terminal\command]
@="wt.exe -d \"%V\""

[HKEY_CLASSES_ROOT\Directory\background\shell\00Terminal]
"Position"="Top"
"MUIVerb"="Terminal Here"
"Icon"="wt.exe"
[HKEY_CLASSES_ROOT\Directory\background\shell\00Terminal\command]
@="wt.exe -d \"%W\""

[HKEY_CLASSES_ROOT\Drive\shell\00Terminal]
"Position"="Top"
"MUIVerb"="Terminal Here"
"Icon"="wt.exe"
[HKEY_CLASSES_ROOT\Drive\shell\00Terminal\command]
@="wt.exe -d \"%V\""

; Terminal Admin - Quick Elevated Access
[HKEY_CLASSES_ROOT\Directory\shell\00TerminalAdmin]
"Position"="Top"
"MUIVerb"="Terminal (Admin)"
"Icon"="wt.exe"
"HasLUAShield"=""
[HKEY_CLASSES_ROOT\Directory\shell\00TerminalAdmin\command]
@="powershell.exe -WindowStyle Hidden -Command \"Start-Process -FilePath 'wt.exe' -ArgumentList '-d', '%V' -Verb RunAs\""

[HKEY_CLASSES_ROOT\Directory\background\shell\00TerminalAdmin]
"Position"="Top"
"MUIVerb"="Terminal (Admin)"
"Icon"="wt.exe"
"HasLUAShield"=""
[HKEY_CLASSES_ROOT\Directory\background\shell\00TerminalAdmin\command]
@="powershell.exe -WindowStyle Hidden -Command \"Start-Process -FilePath 'wt.exe' -ArgumentList '-d', '%W' -Verb RunAs\""

[HKEY_CLASSES_ROOT\Drive\shell\00TerminalAdmin]
"Position"="Top"
"MUIVerb"="Terminal (Admin)"
"Icon"="wt.exe"
"HasLUAShield"=""
[HKEY_CLASSES_ROOT\Drive\shell\00TerminalAdmin\command]
@="powershell.exe -WindowStyle Hidden -Command \"Start-Process -FilePath 'wt.exe' -ArgumentList '-d', '%V' -Verb RunAs\""

; Command Prompt Submenu
[HKEY_CLASSES_ROOT\Directory\shell\01MenuCmd]
"MUIVerb"="Command Prompts"
"Icon"="cmd.exe"
"ExtendedSubCommandsKey"="Directory\\ContextMenus\\MenuCmd"

[HKEY_CLASSES_ROOT\Directory\background\shell\01MenuCmd]
"MUIVerb"="Command Prompts"
"Icon"="cmd.exe"
"ExtendedSubCommandsKey"="Directory\\ContextMenus\\MenuCmd"

[HKEY_CLASSES_ROOT\Drive\shell\01MenuCmd]
"MUIVerb"="Command Prompts"
"Icon"="cmd.exe"
"ExtendedSubCommandsKey"="Directory\\ContextMenus\\MenuCmd"

[HKEY_CLASSES_ROOT\Directory\ContextMenus\MenuCmd\shell\open]
"MUIVerb"="Command Prompt"
"Icon"="cmd.exe"
[HKEY_CLASSES_ROOT\Directory\ContextMenus\MenuCmd\shell\open\command]
@="cmd.exe /s /k pushd \"%V\""

[HKEY_CLASSES_ROOT\Directory\ContextMenus\MenuCmd\shell\runas]
"MUIVerb"="Command Prompt (Admin)"
"Icon"="cmd.exe"
"HasLUAShield"=""
[HKEY_CLASSES_ROOT\Directory\ContextMenus\MenuCmd\shell\runas\command]
@="powershell.exe -WindowStyle Hidden -Command \"Start-Process -FilePath 'cmd.exe' -ArgumentList '/s', '/k', 'pushd %V' -Verb RunAs\""

[HKEY_CLASSES_ROOT\Directory\ContextMenus\MenuCmd\shell\terminal]
"MUIVerb"="CMD in Terminal"
"Icon"="wt.exe"
[HKEY_CLASSES_ROOT\Directory\ContextMenus\MenuCmd\shell\terminal\command]
@="wt.exe -d \"%V\" cmd"

; PowerShell Submenu
[HKEY_CLASSES_ROOT\Directory\shell\02MenuPowerShell]
"MUIVerb"="PowerShell Prompts"
"Icon"="powershell.exe"
"ExtendedSubCommandsKey"="Directory\\ContextMenus\\MenuPowerShell"

[HKEY_CLASSES_ROOT\Directory\background\shell\02MenuPowerShell]
"MUIVerb"="PowerShell Prompts"
"Icon"="powershell.exe"
"ExtendedSubCommandsKey"="Directory\\ContextMenus\\MenuPowerShell"

[HKEY_CLASSES_ROOT\Drive\shell\02MenuPowerShell]
"MUIVerb"="PowerShell Prompts"
"Icon"="powershell.exe"
"ExtendedSubCommandsKey"="Directory\\ContextMenus\\MenuPowerShell"

[HKEY_CLASSES_ROOT\Directory\ContextMenus\MenuPowerShell\shell\ps5]
"MUIVerb"="PowerShell 5.1"
"Icon"="powershell.exe"
[HKEY_CLASSES_ROOT\Directory\ContextMenus\MenuPowerShell\shell\ps5\command]
@="powershell.exe -NoExit -Command \"Set-Location -LiteralPath '%V'\""

[HKEY_CLASSES_ROOT\Directory\ContextMenus\MenuPowerShell\shell\ps5admin]
"MUIVerb"="PowerShell 5.1 (Admin)"
"Icon"="powershell.exe"
"HasLUAShield"=""
[HKEY_CLASSES_ROOT\Directory\ContextMenus\MenuPowerShell\shell\ps5admin\command]
@="powershell.exe -WindowStyle Hidden -Command \"Start-Process -FilePath 'powershell.exe' -ArgumentList '-NoExit', '-Command', \\\"Set-Location -LiteralPath '%V'\\\" -Verb RunAs\""

"@

# Add PowerShell 7 entries if installed
if ($tools.PowerShell7.Found) {
    $ps7Path = ConvertTo-RegPath $tools.PowerShell7.Path
    $regContent += @"

; PowerShell 7
[HKEY_CLASSES_ROOT\Directory\ContextMenus\MenuPowerShell\shell\ps7]
"MUIVerb"="PowerShell 7"
"Icon"="$ps7Path"
[HKEY_CLASSES_ROOT\Directory\ContextMenus\MenuPowerShell\shell\ps7\command]
@="\"$ps7Path\" -NoExit -WorkingDirectory \"%V\""

[HKEY_CLASSES_ROOT\Directory\ContextMenus\MenuPowerShell\shell\ps7admin]
"MUIVerb"="PowerShell 7 (Admin)"
"Icon"="$ps7Path"
"HasLUAShield"=""
[HKEY_CLASSES_ROOT\Directory\ContextMenus\MenuPowerShell\shell\ps7admin\command]
@="powershell.exe -WindowStyle Hidden -Command \"Start-Process -FilePath '$ps7Path' -ArgumentList '-NoExit', '-WorkingDirectory', '%V' -Verb RunAs\""

"@
}

$regContent += @"

[HKEY_CLASSES_ROOT\Directory\ContextMenus\MenuPowerShell\shell\psterminal]
"MUIVerb"="PowerShell in Terminal"
"Icon"="wt.exe"
[HKEY_CLASSES_ROOT\Directory\ContextMenus\MenuPowerShell\shell\psterminal\command]
@="wt.exe -d \"%V\" powershell"

"@

# Add Developer Tools submenu if any dev tools are found
if ($tools.VSCode.Found -or $tools.GitBash.Found -or $tools.WSL.Found) {
    
    $devIcon = if ($tools.VSCode.Found) { 
        ConvertTo-RegPath $tools.VSCode.Path 
    } else { 
        "cmd.exe" 
    }
    
    $regContent += @"

; Developer Tools Submenu
[HKEY_CLASSES_ROOT\Directory\shell\03MenuDev]
"MUIVerb"="Developer Tools"
"Icon"="$devIcon"
"ExtendedSubCommandsKey"="Directory\\ContextMenus\\MenuDev"

[HKEY_CLASSES_ROOT\Directory\background\shell\03MenuDev]
"MUIVerb"="Developer Tools"
"Icon"="$devIcon"
"ExtendedSubCommandsKey"="Directory\\ContextMenus\\MenuDev"

[HKEY_CLASSES_ROOT\Drive\shell\03MenuDev]
"MUIVerb"="Developer Tools"
"Icon"="$devIcon"
"ExtendedSubCommandsKey"="Directory\\ContextMenus\\MenuDev"

"@

    # VS Code
    if ($tools.VSCode.Found) {
        $vscodePath = ConvertTo-RegPath $tools.VSCode.Path
        $regContent += @"

[HKEY_CLASSES_ROOT\Directory\ContextMenus\MenuDev\shell\vscode]
"MUIVerb"="Open with VS Code"
"Icon"="$vscodePath"
[HKEY_CLASSES_ROOT\Directory\ContextMenus\MenuDev\shell\vscode\command]
@="\"$vscodePath\" \"%V\""

"@
    }

    # WSL
    if ($tools.WSL.Found) {
        $regContent += @"

[HKEY_CLASSES_ROOT\Directory\ContextMenus\MenuDev\shell\wsl]
"MUIVerb"="WSL Here"
"Icon"="wsl.exe"
[HKEY_CLASSES_ROOT\Directory\ContextMenus\MenuDev\shell\wsl\command]
@="wt.exe -d \"%V\" wsl"

"@
    }

    # Git Bash
    if ($tools.GitBash.Found) {
        $gitPath = ConvertTo-RegPath $tools.GitBash.Path
        $regContent += @"

[HKEY_CLASSES_ROOT\Directory\ContextMenus\MenuDev\shell\gitbash]
"MUIVerb"="Git Bash"
"Icon"="$gitPath"
[HKEY_CLASSES_ROOT\Directory\ContextMenus\MenuDev\shell\gitbash\command]
@="\"$gitPath\" \"--cd=%V\""

"@
    }
}

# Hide default Windows entries
$regContent += @"

; Hide default Windows entries (show only with Shift+Right-Click)
[HKEY_CLASSES_ROOT\Directory\shell\cmd]
"Extended"=""
[HKEY_CLASSES_ROOT\Directory\background\shell\cmd]
"Extended"=""
[HKEY_CLASSES_ROOT\Directory\shell\Powershell]
"Extended"=""
[HKEY_CLASSES_ROOT\Directory\background\shell\Powershell]
"Extended"=""
[HKEY_CLASSES_ROOT\Directory\shell\git_gui]
"Extended"=""
[HKEY_CLASSES_ROOT\Directory\shell\git_shell]
"Extended"=""

; Remove default Windows 11 Terminal entry
[-HKEY_CLASSES_ROOT\Directory\shell\OpenInTerminal]
[-HKEY_CLASSES_ROOT\Directory\background\shell\OpenInTerminal]
"@

#endregion

#region Undo Registry Generation

$undoContent = @"
Windows Registry Editor Version 5.00

; ============================================
; UNDO CUSTOM CONTEXT MENU
; Generated: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
; ============================================
; This removes all custom entries and restores Windows defaults.

; Remove custom Terminal entries
[-HKEY_CLASSES_ROOT\Directory\shell\00Terminal]
[-HKEY_CLASSES_ROOT\Directory\background\shell\00Terminal]
[-HKEY_CLASSES_ROOT\Drive\shell\00Terminal]
[-HKEY_CLASSES_ROOT\Directory\shell\00TerminalAdmin]
[-HKEY_CLASSES_ROOT\Directory\background\shell\00TerminalAdmin]
[-HKEY_CLASSES_ROOT\Drive\shell\00TerminalAdmin]

; Remove Command Prompt submenu
[-HKEY_CLASSES_ROOT\Directory\shell\01MenuCmd]
[-HKEY_CLASSES_ROOT\Directory\background\shell\01MenuCmd]
[-HKEY_CLASSES_ROOT\Drive\shell\01MenuCmd]
[-HKEY_CLASSES_ROOT\Directory\ContextMenus\MenuCmd]

; Remove PowerShell submenu
[-HKEY_CLASSES_ROOT\Directory\shell\02MenuPowerShell]
[-HKEY_CLASSES_ROOT\Directory\background\shell\02MenuPowerShell]
[-HKEY_CLASSES_ROOT\Drive\shell\02MenuPowerShell]
[-HKEY_CLASSES_ROOT\Directory\ContextMenus\MenuPowerShell]

; Remove Developer Tools submenu
[-HKEY_CLASSES_ROOT\Directory\shell\03MenuDev]
[-HKEY_CLASSES_ROOT\Directory\background\shell\03MenuDev]
[-HKEY_CLASSES_ROOT\Drive\shell\03MenuDev]
[-HKEY_CLASSES_ROOT\Directory\ContextMenus\MenuDev]

; Restore default Windows entries
[HKEY_CLASSES_ROOT\Directory\shell\cmd]
"Extended"=-
[HKEY_CLASSES_ROOT\Directory\background\shell\cmd]
"Extended"=-
[HKEY_CLASSES_ROOT\Directory\shell\Powershell]
"Extended"=-
[HKEY_CLASSES_ROOT\Directory\background\shell\Powershell]
"Extended"=-
[HKEY_CLASSES_ROOT\Directory\shell\git_gui]
"Extended"=-
[HKEY_CLASSES_ROOT\Directory\shell\git_shell]
"Extended"=-
"@

#endregion

#region Write Files

$customRegPath = Join-Path $OutputPath "ContextMenu-Custom.reg"
$undoRegPath = Join-Path $OutputPath "ContextMenu-Undo.reg"

try {
    # Write custom registry file
    [System.IO.File]::WriteAllText($customRegPath, $regContent, [System.Text.Encoding]::Unicode)
    Write-ColorOutput "`n✓ Generated: $customRegPath" "Green"
    
    # Write undo registry file
    [System.IO.File]::WriteAllText($undoRegPath, $undoContent, [System.Text.Encoding]::Unicode)
    Write-ColorOutput "✓ Generated: $undoRegPath" "Green"
    
    Write-ColorOutput "`n=== Installation Instructions ===" "Cyan"
    Write-ColorOutput "1. Double-click 'ContextMenu-Custom.reg' to install" "White"
    Write-ColorOutput "2. Click 'Yes' when prompted by UAC" "White"
    Write-ColorOutput "3. Restart Explorer or log off/on to see changes" "White"
    Write-ColorOutput "`nTo restore defaults: Double-click 'ContextMenu-Undo.reg'" "Yellow"
    
    # Offer to apply immediately
    Write-ColorOutput "`nApply registry changes now? (Requires admin)" "Yellow"
    $apply = Read-Host "Type 'yes' to apply, or press Enter to skip"
    
    if ($apply -eq 'yes') {
        $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
        
        if (-not $isAdmin) {
            Write-ColorOutput "Relaunching as administrator..." "Yellow"
            Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -Command `"& {regedit /s '$customRegPath'; Write-Host 'Registry imported successfully!'; Read-Host 'Press Enter to close'}`"" -Verb RunAs
        } else {
            regedit /s $customRegPath
            Write-ColorOutput "`n✓ Registry updated! Restart Explorer to see changes." "Green"
            Write-ColorOutput "Run: taskkill /f /im explorer.exe; start explorer" "Yellow"
        }
    }
    
} catch {
    Write-ColorOutput "`n✗ Error writing files: $_" "Red"
    exit 1
}

#endregion
