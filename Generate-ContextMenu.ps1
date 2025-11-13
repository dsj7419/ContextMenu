param([string]$OutputPath = "")

if ($OutputPath -eq "") {
    if ($PSScriptRoot) { $OutputPath = $PSScriptRoot } else { $OutputPath = (Get-Location).Path }
}

function Find-Tool {
    param([string[]]$Paths, [string]$Name)
    foreach ($p in $Paths) {
        $expanded = [Environment]::ExpandEnvironmentVariables($p)
        if (Test-Path $expanded) { return $expanded }
    }
    $cmd = Get-Command $Name -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }
    return $null
}

function Escape-RegPath {
    param([string]$Path)
    return $Path -replace '\\', '\\\\'
}

Write-Host ""
Write-Host "=== Context Menu Generator ===" -ForegroundColor Cyan
Write-Host "Detecting tools..." -ForegroundColor Yellow
Write-Host ""

$vscode = Find-Tool -Paths @("$env:ProgramFiles\Microsoft VS Code\Code.exe", "$env:LOCALAPPDATA\Programs\Microsoft VS Code\Code.exe") -Name "Code.exe"
$gitbash = Find-Tool -Paths @("$env:ProgramFiles\Git\git-bash.exe", "${env:ProgramFiles(x86)}\Git\git-bash.exe") -Name "git-bash.exe"
$ps7 = Find-Tool -Paths @("$env:ProgramFiles\PowerShell\7\pwsh.exe", "$env:LOCALAPPDATA\Microsoft\PowerShell\7\pwsh.exe") -Name "pwsh.exe"
$wsl = Find-Tool -Paths @("$env:SystemRoot\System32\wsl.exe") -Name "wsl.exe"
$wt = Find-Tool -Paths @("wt.exe") -Name "wt.exe"

if ($vscode) { Write-Host "  [+] VS Code: $vscode" -ForegroundColor Green } else { Write-Host "  [-] VS Code: Not found" -ForegroundColor DarkGray }
if ($gitbash) { Write-Host "  [+] Git Bash: $gitbash" -ForegroundColor Green } else { Write-Host "  [-] Git Bash: Not found" -ForegroundColor DarkGray }
if ($ps7) { Write-Host "  [+] PowerShell 7: $ps7" -ForegroundColor Green } else { Write-Host "  [-] PowerShell 7: Not found" -ForegroundColor DarkGray }
if ($wsl) { Write-Host "  [+] WSL: $wsl" -ForegroundColor Green } else { Write-Host "  [-] WSL: Not found" -ForegroundColor DarkGray }
if ($wt) { Write-Host "  [+] Windows Terminal: $wt" -ForegroundColor Green } else { Write-Host "  [-] Windows Terminal: Not found" -ForegroundColor DarkGray }

if (-not $wt) {
    Write-Host ""
    Write-Host "ERROR: Windows Terminal required! Install from Microsoft Store." -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Generating files..." -ForegroundColor Yellow

$customPath = Join-Path $OutputPath "ContextMenu-Custom.reg"
$undoPath = Join-Path $OutputPath "ContextMenu-Undo.reg"

$custom = @()
$custom += "Windows Registry Editor Version 5.00"
$custom += ""
$custom += "; Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
$custom += ""
$custom += "[HKEY_CLASSES_ROOT\Directory\shell\00Terminal]"
$custom += '"Position"="Top"'
$custom += '"MUIVerb"="Terminal Here"'
$custom += '"Icon"="wt.exe"'
$custom += "[HKEY_CLASSES_ROOT\Directory\shell\00Terminal\command]"
$custom += '@="wt.exe -d \""%V"""'
$custom += ""
$custom += "[HKEY_CLASSES_ROOT\Directory\background\shell\00Terminal]"
$custom += '"Position"="Top"'
$custom += '"MUIVerb"="Terminal Here"'
$custom += '"Icon"="wt.exe"'
$custom += "[HKEY_CLASSES_ROOT\Directory\background\shell\00Terminal\command]"
$custom += '@="wt.exe -d \""%W"""'
$custom += ""
$custom += "[HKEY_CLASSES_ROOT\Drive\shell\00Terminal]"
$custom += '"Position"="Top"'
$custom += '"MUIVerb"="Terminal Here"'
$custom += '"Icon"="wt.exe"'
$custom += "[HKEY_CLASSES_ROOT\Drive\shell\00Terminal\command]"
$custom += '@="wt.exe -d \""%V"""'
$custom += ""
$custom += "[HKEY_CLASSES_ROOT\Directory\shell\00TerminalAdmin]"
$custom += '"Position"="Top"'
$custom += '"MUIVerb"="Terminal (Admin)"'
$custom += '"Icon"="wt.exe"'
$custom += '"HasLUAShield"=""'
$custom += "[HKEY_CLASSES_ROOT\Directory\shell\00TerminalAdmin\command]"
$custom += '@="powershell.exe -WindowStyle Hidden -Command ""Start-Process -FilePath ' + "'" + 'wt.exe' + "'" + ' -ArgumentList ' + "'" + '-d' + "'" + ', ' + "'" + '%V' + "'" + ' -Verb RunAs"""'
$custom += ""
$custom += "[HKEY_CLASSES_ROOT\Directory\background\shell\00TerminalAdmin]"
$custom += '"Position"="Top"'
$custom += '"MUIVerb"="Terminal (Admin)"'
$custom += '"Icon"="wt.exe"'
$custom += '"HasLUAShield"=""'
$custom += "[HKEY_CLASSES_ROOT\Directory\background\shell\00TerminalAdmin\command]"
$custom += '@="powershell.exe -WindowStyle Hidden -Command ""Start-Process -FilePath ' + "'" + 'wt.exe' + "'" + ' -ArgumentList ' + "'" + '-d' + "'" + ', ' + "'" + '%W' + "'" + ' -Verb RunAs"""'
$custom += ""
$custom += "[HKEY_CLASSES_ROOT\Drive\shell\00TerminalAdmin]"
$custom += '"Position"="Top"'
$custom += '"MUIVerb"="Terminal (Admin)"'
$custom += '"Icon"="wt.exe"'
$custom += '"HasLUAShield"=""'
$custom += "[HKEY_CLASSES_ROOT\Drive\shell\00TerminalAdmin\command]"
$custom += '@="powershell.exe -WindowStyle Hidden -Command ""Start-Process -FilePath ' + "'" + 'wt.exe' + "'" + ' -ArgumentList ' + "'" + '-d' + "'" + ', ' + "'" + '%V' + "'" + ' -Verb RunAs"""'
$custom += ""
$custom += "[HKEY_CLASSES_ROOT\Directory\shell\01MenuCmd]"
$custom += '"MUIVerb"="Command Prompts"'
$custom += '"Icon"="cmd.exe"'
$custom += '"ExtendedSubCommandsKey"="Directory\\ContextMenus\\MenuCmd"'
$custom += ""
$custom += "[HKEY_CLASSES_ROOT\Directory\background\shell\01MenuCmd]"
$custom += '"MUIVerb"="Command Prompts"'
$custom += '"Icon"="cmd.exe"'
$custom += '"ExtendedSubCommandsKey"="Directory\\ContextMenus\\MenuCmd"'
$custom += ""
$custom += "[HKEY_CLASSES_ROOT\Drive\shell\01MenuCmd]"
$custom += '"MUIVerb"="Command Prompts"'
$custom += '"Icon"="cmd.exe"'
$custom += '"ExtendedSubCommandsKey"="Directory\\ContextMenus\\MenuCmd"'
$custom += ""
$custom += "[HKEY_CLASSES_ROOT\Directory\ContextMenus\MenuCmd\shell\open]"
$custom += '"MUIVerb"="Command Prompt"'
$custom += '"Icon"="cmd.exe"'
$custom += "[HKEY_CLASSES_ROOT\Directory\ContextMenus\MenuCmd\shell\open\command]"
$custom += '@="cmd.exe /s /k pushd \""%V"""'
$custom += ""
$custom += "[HKEY_CLASSES_ROOT\Directory\ContextMenus\MenuCmd\shell\runas]"
$custom += '"MUIVerb"="Command Prompt (Admin)"'
$custom += '"Icon"="cmd.exe"'
$custom += '"HasLUAShield"=""'
$custom += "[HKEY_CLASSES_ROOT\Directory\ContextMenus\MenuCmd\shell\runas\command]"
$custom += '@="powershell.exe -WindowStyle Hidden -Command ""Start-Process -FilePath ' + "'" + 'cmd.exe' + "'" + ' -ArgumentList ' + "'" + '/s' + "'" + ', ' + "'" + '/k' + "'" + ', ' + "'" + 'pushd %V' + "'" + ' -Verb RunAs"""'
$custom += ""
$custom += "[HKEY_CLASSES_ROOT\Directory\ContextMenus\MenuCmd\shell\terminal]"
$custom += '"MUIVerb"="CMD in Terminal"'
$custom += '"Icon"="wt.exe"'
$custom += "[HKEY_CLASSES_ROOT\Directory\ContextMenus\MenuCmd\shell\terminal\command]"
$custom += '@="wt.exe -d \""%V\"" cmd"'
$custom += ""
$custom += "[HKEY_CLASSES_ROOT\Directory\shell\02MenuPowerShell]"
$custom += '"MUIVerb"="PowerShell Prompts"'
$custom += '"Icon"="powershell.exe"'
$custom += '"ExtendedSubCommandsKey"="Directory\\ContextMenus\\MenuPowerShell"'
$custom += ""
$custom += "[HKEY_CLASSES_ROOT\Directory\background\shell\02MenuPowerShell]"
$custom += '"MUIVerb"="PowerShell Prompts"'
$custom += '"Icon"="powershell.exe"'
$custom += '"ExtendedSubCommandsKey"="Directory\\ContextMenus\\MenuPowerShell"'
$custom += ""
$custom += "[HKEY_CLASSES_ROOT\Drive\shell\02MenuPowerShell]"
$custom += '"MUIVerb"="PowerShell Prompts"'
$custom += '"Icon"="powershell.exe"'
$custom += '"ExtendedSubCommandsKey"="Directory\\ContextMenus\\MenuPowerShell"'
$custom += ""
$custom += "[HKEY_CLASSES_ROOT\Directory\ContextMenus\MenuPowerShell\shell\ps5]"
$custom += '"MUIVerb"="PowerShell 5.1"'
$custom += '"Icon"="powershell.exe"'
$custom += "[HKEY_CLASSES_ROOT\Directory\ContextMenus\MenuPowerShell\shell\ps5\command]"
$custom += '@="powershell.exe -NoExit -Command ""Set-Location -LiteralPath ' + "'" + '%V' + "'" + '"""'
$custom += ""
$custom += "[HKEY_CLASSES_ROOT\Directory\ContextMenus\MenuPowerShell\shell\ps5admin]"
$custom += '"MUIVerb"="PowerShell 5.1 (Admin)"'
$custom += '"Icon"="powershell.exe"'
$custom += '"HasLUAShield"=""'
$custom += "[HKEY_CLASSES_ROOT\Directory\ContextMenus\MenuPowerShell\shell\ps5admin\command]"
$custom += '@="powershell.exe -WindowStyle Hidden -Command ""Start-Process -FilePath ' + "'" + 'powershell.exe' + "'" + ' -ArgumentList ' + "'" + '-NoExit' + "'" + ', ' + "'" + '-Command' + "'" + ', ' + '\' + '""Set-Location -LiteralPath ' + "'" + '%V' + "'" + '\' + '""' + ' -Verb RunAs"""'
$custom += ""

if ($ps7) {
    $ps7esc = Escape-RegPath $ps7
    $custom += "[HKEY_CLASSES_ROOT\Directory\ContextMenus\MenuPowerShell\shell\ps7]"
    $custom += '"MUIVerb"="PowerShell 7"'
    $custom += ('"Icon"="' + $ps7esc + '"')
    $custom += "[HKEY_CLASSES_ROOT\Directory\ContextMenus\MenuPowerShell\shell\ps7\command]"
    $custom += ('@="\"' + $ps7esc + '\" -NoExit -WorkingDirectory \"%V\""')
    $custom += ""
    $custom += "[HKEY_CLASSES_ROOT\Directory\ContextMenus\MenuPowerShell\shell\ps7admin]"
    $custom += '"MUIVerb"="PowerShell 7 (Admin)"'
    $custom += ('"Icon"="' + $ps7esc + '"')
    $custom += '"HasLUAShield"=""'
    $custom += "[HKEY_CLASSES_ROOT\Directory\ContextMenus\MenuPowerShell\shell\ps7admin\command]"
    $custom += ('@="powershell.exe -WindowStyle Hidden -Command ""Start-Process -FilePath ' + "'" + $ps7 + "'" + ' -ArgumentList ' + "'" + '-NoExit' + "'" + ', ' + "'" + '-WorkingDirectory' + "'" + ', ' + "'" + '%V' + "'" + ' -Verb RunAs"""')
    $custom += ""
}

$custom += "[HKEY_CLASSES_ROOT\Directory\ContextMenus\MenuPowerShell\shell\psterminal]"
$custom += '"MUIVerb"="PowerShell in Terminal"'
$custom += '"Icon"="wt.exe"'
$custom += "[HKEY_CLASSES_ROOT\Directory\ContextMenus\MenuPowerShell\shell\psterminal\command]"
$custom += '@="wt.exe -d \""%V\"" powershell"'
$custom += ""

if ($vscode -or $gitbash -or $wsl) {
    $icon = if ($vscode) { Escape-RegPath $vscode } else { "cmd.exe" }
    $custom += "[HKEY_CLASSES_ROOT\Directory\shell\03MenuDev]"
    $custom += '"MUIVerb"="Developer Tools"'
    $custom += ('"Icon"="' + $icon + '"')
    $custom += '"ExtendedSubCommandsKey"="Directory\\ContextMenus\\MenuDev"'
    $custom += ""
    $custom += "[HKEY_CLASSES_ROOT\Directory\background\shell\03MenuDev]"
    $custom += '"MUIVerb"="Developer Tools"'
    $custom += ('"Icon"="' + $icon + '"')
    $custom += '"ExtendedSubCommandsKey"="Directory\\ContextMenus\\MenuDev"'
    $custom += ""
    $custom += "[HKEY_CLASSES_ROOT\Drive\shell\03MenuDev]"
    $custom += '"MUIVerb"="Developer Tools"'
    $custom += ('"Icon"="' + $icon + '"')
    $custom += '"ExtendedSubCommandsKey"="Directory\\ContextMenus\\MenuDev"'
    $custom += ""

    if ($vscode) {
        $vscesc = Escape-RegPath $vscode
        $custom += "[HKEY_CLASSES_ROOT\Directory\ContextMenus\MenuDev\shell\vscode]"
        $custom += '"MUIVerb"="Open with VS Code"'
        $custom += ('"Icon"="' + $vscesc + '"')
        $custom += "[HKEY_CLASSES_ROOT\Directory\ContextMenus\MenuDev\shell\vscode\command]"
        $custom += ('@="\"' + $vscesc + '\" \"%V\""')
        $custom += ""
    }

    if ($wsl) {
        $custom += "[HKEY_CLASSES_ROOT\Directory\ContextMenus\MenuDev\shell\wsl]"
        $custom += '"MUIVerb"="WSL Here"'
        $custom += '"Icon"="wsl.exe"'
        $custom += "[HKEY_CLASSES_ROOT\Directory\ContextMenus\MenuDev\shell\wsl\command]"
        $custom += '@="wt.exe -d \""%V\"" wsl"'
        $custom += ""
    }

    if ($gitbash) {
        $gitesc = Escape-RegPath $gitbash
        $custom += "[HKEY_CLASSES_ROOT\Directory\ContextMenus\MenuDev\shell\gitbash]"
        $custom += '"MUIVerb"="Git Bash"'
        $custom += ('"Icon"="' + $gitesc + '"')
        $custom += "[HKEY_CLASSES_ROOT\Directory\ContextMenus\MenuDev\shell\gitbash\command]"
        $custom += ('@="\"' + $gitesc + '\" \"--cd=%V\""')
        $custom += ""
    }
}

$custom += "[HKEY_CLASSES_ROOT\Directory\shell\cmd]"
$custom += '"Extended"=""'
$custom += "[HKEY_CLASSES_ROOT\Directory\background\shell\cmd]"
$custom += '"Extended"=""'
$custom += "[HKEY_CLASSES_ROOT\Directory\shell\Powershell]"
$custom += '"Extended"=""'
$custom += "[HKEY_CLASSES_ROOT\Directory\background\shell\Powershell]"
$custom += '"Extended"=""'
$custom += "[HKEY_CLASSES_ROOT\Directory\shell\git_gui]"
$custom += '"Extended"=""'
$custom += "[HKEY_CLASSES_ROOT\Directory\shell\git_shell]"
$custom += '"Extended"=""'
$custom += ""
$custom += "[-HKEY_CLASSES_ROOT\Directory\shell\OpenInTerminal]"
$custom += "[-HKEY_CLASSES_ROOT\Directory\background\shell\OpenInTerminal]"

$undo = @()
$undo += "Windows Registry Editor Version 5.00"
$undo += ""
$undo += "[-HKEY_CLASSES_ROOT\Directory\shell\00Terminal]"
$undo += "[-HKEY_CLASSES_ROOT\Directory\background\shell\00Terminal]"
$undo += "[-HKEY_CLASSES_ROOT\Drive\shell\00Terminal]"
$undo += "[-HKEY_CLASSES_ROOT\Directory\shell\00TerminalAdmin]"
$undo += "[-HKEY_CLASSES_ROOT\Directory\background\shell\00TerminalAdmin]"
$undo += "[-HKEY_CLASSES_ROOT\Drive\shell\00TerminalAdmin]"
$undo += "[-HKEY_CLASSES_ROOT\Directory\shell\01MenuCmd]"
$undo += "[-HKEY_CLASSES_ROOT\Directory\background\shell\01MenuCmd]"
$undo += "[-HKEY_CLASSES_ROOT\Drive\shell\01MenuCmd]"
$undo += "[-HKEY_CLASSES_ROOT\Directory\ContextMenus\MenuCmd]"
$undo += "[-HKEY_CLASSES_ROOT\Directory\shell\02MenuPowerShell]"
$undo += "[-HKEY_CLASSES_ROOT\Directory\background\shell\02MenuPowerShell]"
$undo += "[-HKEY_CLASSES_ROOT\Drive\shell\02MenuPowerShell]"
$undo += "[-HKEY_CLASSES_ROOT\Directory\ContextMenus\MenuPowerShell]"
$undo += "[-HKEY_CLASSES_ROOT\Directory\shell\03MenuDev]"
$undo += "[-HKEY_CLASSES_ROOT\Directory\background\shell\03MenuDev]"
$undo += "[-HKEY_CLASSES_ROOT\Drive\shell\03MenuDev]"
$undo += "[-HKEY_CLASSES_ROOT\Directory\ContextMenus\MenuDev]"
$undo += ""
$undo += "[HKEY_CLASSES_ROOT\Directory\shell\cmd]"
$undo += '"Extended"=-'
$undo += "[HKEY_CLASSES_ROOT\Directory\background\shell\cmd]"
$undo += '"Extended"=-'
$undo += "[HKEY_CLASSES_ROOT\Directory\shell\Powershell]"
$undo += '"Extended"=-'
$undo += "[HKEY_CLASSES_ROOT\Directory\background\shell\Powershell]"
$undo += '"Extended"=-'
$undo += "[HKEY_CLASSES_ROOT\Directory\shell\git_gui]"
$undo += '"Extended"=-'
$undo += "[HKEY_CLASSES_ROOT\Directory\shell\git_shell]"
$undo += '"Extended"=-'

[System.IO.File]::WriteAllLines($customPath, $custom, [System.Text.Encoding]::Unicode)
[System.IO.File]::WriteAllLines($undoPath, $undo, [System.Text.Encoding]::Unicode)

Write-Host ""
Write-Host "[SUCCESS] $customPath" -ForegroundColor Green
Write-Host "[SUCCESS] $undoPath" -ForegroundColor Green
Write-Host ""
Write-Host "=== INSTALL ===" -ForegroundColor Cyan
Write-Host "1. Double-click ContextMenu-Custom.reg" -ForegroundColor White
Write-Host "2. Click Yes" -ForegroundColor White
Write-Host "3. Restart Explorer" -ForegroundColor White
Write-Host ""
Write-Host "Apply now? (yes/no)" -ForegroundColor Yellow
$apply = Read-Host

if ($apply -eq 'yes') {
    $isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    if (-not $isAdmin) {
        Write-Host "Launching as admin..." -ForegroundColor Yellow
        $argList = "-NoProfile -ExecutionPolicy Bypass -Command `"regedit /s '$customPath'; Write-Host 'Done'; Read-Host 'Press Enter'`""
        Start-Process powershell.exe -ArgumentList $argList -Verb RunAs
    } else {
        regedit /s "$customPath"
        Write-Host ""
        Write-Host "[DONE] Restart Explorer now" -ForegroundColor Green
    }
}
