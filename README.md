# Windows Context Menu Generator

A PowerShell script that creates a clean, organized right-click context menu for Windows 10/11 with automatic tool detection and proper elevation support.

## Why This Exists

The default Windows context menu is cluttered and inconsistent. This project gives you a streamlined menu structure with:

- **Ordered entries** that stay in the position you want (using numeric prefixes)
- **Proper admin elevation** for Terminal, PowerShell, and CMD
- **Smart submenus** that organize related tools without cluttering the main menu
- **Auto-detection** of installed tools so the menu only shows what you actually have
- **Validated paths** that work regardless of whether you installed tools system-wide or per-user

### What Changed from v1

The original approach used a static `.reg` file with hardcoded paths. This caused issues:
- Paths broke when tools were installed to different locations
- No validation of whether tools were actually installed
- Manual editing required for different machines
- Admin commands didn't actually elevate properly

The new PowerShell generator solves all of this by detecting your installed tools and building the registry file dynamically with correct paths and proper elevation commands.

## Features

### 🚀 Primary Access
- **Terminal Here** - Opens Windows Terminal in the current directory
- **Terminal (Admin)** - Elevated Windows Terminal with UAC prompt

### 📂 Command Prompts Submenu
- Command Prompt
- Command Prompt (Admin)
- CMD in Terminal

### 💻 PowerShell Prompts Submenu
- PowerShell 5.1
- PowerShell 5.1 (Admin)
- PowerShell 7 *(if installed)*
- PowerShell 7 (Admin) *(if installed)*
- PowerShell in Terminal

### 🛠️ Developer Tools Submenu
*(Only appears if you have at least one tool installed)*
- Open with VS Code *(if installed)*
- WSL Here *(if installed)*
- Git Bash *(if installed)*

### 🧹 Cleanup
- Hides default Windows entries (accessible via Shift+Right-Click)
- Removes duplicate "Open in Terminal" entry from Windows 11

## Prerequisites

- **Windows 10 or 11**
- **Windows Terminal** - Required (install from Microsoft Store if needed)
- **PowerShell 5.1 or later** - Pre-installed on Windows 10/11

Optional tools (auto-detected):
- Visual Studio Code
- Git Bash
- PowerShell 7
- WSL (Windows Subsystem for Linux)

## Installation

### Quick Start

1. **Download** the `Generate-ContextMenu.ps1` script
2. **Open PowerShell** in the script's directory
3. **Run the generator:**
   ```powershell
   powershell -ExecutionPolicy Bypass -File .\Generate-ContextMenu.ps1
   ```
4. **Type `yes`** when prompted to apply changes automatically
5. **Restart Explorer** (the script offers to do this for you)

### Manual Installation

If you prefer to review the generated registry files before applying:

```powershell
# Generate the files
powershell -ExecutionPolicy Bypass -File .\Generate-ContextMenu.ps1

# Press Enter when asked about applying changes

# Review the generated files:
# - ContextMenu-Custom.reg (your new menu)
# - ContextMenu-Undo.reg (restoration file)

# Apply manually
regedit /s ContextMenu-Custom.reg

# Restart Explorer
taskkill /f /im explorer.exe; start explorer
```

## Usage

### Accessing Your New Menu

Right-click any folder, drive, or empty space in Explorer to see your new context menu structure. All entries appear at the top in order:

1. Terminal Here
2. Terminal (Admin)
3. Command Prompts ▸
4. PowerShell Prompts ▸
5. Developer Tools ▸

### Testing Admin Elevation

To verify that admin entries are working correctly:

1. Right-click a folder and choose any "(Admin)" option
2. You should see a UAC prompt
3. Once the shell opens, run `whoami` or check the title bar for "Administrator"

### Regenerating for a Different Machine

The beauty of this approach is portability. On a new machine:

1. Copy `Generate-ContextMenu.ps1` to the new machine
2. Run the script—it auto-detects what's installed on *that* machine
3. Apply the generated registry file

No manual path editing required.

## Customization

### Adding Custom Entries

The script is structured to make customization straightforward. To add your own tools:

1. Open `Generate-ContextMenu.ps1` in your editor
2. Find the `# Add Developer Tools submenu` section
3. Follow the existing pattern to add new tools

Example template:
```powershell
# Your Custom Tool
if ($tools.YourTool.Found) {
    $toolPath = ConvertTo-RegPath $tools.YourTool.Path
    $regContent += @"

[HKEY_CLASSES_ROOT\Directory\ContextMenus\MenuDev\shell\yourtool]
"MUIVerb"="Your Tool Name"
"Icon"="$toolPath"
[HKEY_CLASSES_ROOT\Directory\ContextMenus\MenuDev\shell\yourtool\command]
@="\"$toolPath\" \"%V\""

"@
}
```

### Changing Menu Order

The numeric prefixes (`00`, `01`, `02`, `03`) control the order. To reorder:

1. Change the prefix numbers in the script
2. Regenerate and reapply

Example: To move Developer Tools above PowerShell, change `03MenuDev` to `01MenuDev` and renumber the others.

### Removing Unwanted Sections

Comment out or delete sections you don't need before running the generator:

```powershell
# Don't want Command Prompt submenu? Comment out this section:
# $regContent += @"
# ; Command Prompt Submenu
# ...
# "@
```

## Uninstallation

### Quick Restore

The script generates an undo file automatically. To restore Windows defaults:

```powershell
regedit /s ContextMenu-Undo.reg
taskkill /f /im explorer.exe; start explorer
```

### Manual Cleanup

If you lost the undo file, you can manually remove entries:

1. Open `regedit`
2. Navigate to `HKEY_CLASSES_ROOT\Directory\shell`
3. Delete these keys:
   - `00Terminal`
   - `00TerminalAdmin`
   - `01MenuCmd`
   - `02MenuPowerShell`
   - `03MenuDev`
4. Navigate to `HKEY_CLASSES_ROOT\Directory\ContextMenus`
5. Delete:
   - `MenuCmd`
   - `MenuPowerShell`
   - `MenuDev`
6. Repeat for `Directory\background\shell` and `Drive\shell`

## Troubleshooting

### "Cannot be loaded because running scripts is disabled"

Windows blocks script execution by default. Use the bypass method:

```powershell
powershell -ExecutionPolicy Bypass -File .\Generate-ContextMenu.ps1
```

Or set a permanent policy for your user:

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### "ERROR: Error accessing the registry"

The `reg import` command sometimes fails. Use `regedit` instead:

```powershell
regedit /s ContextMenu-Custom.reg
```

### Admin Entries Don't Show UAC Prompt

If clicking "(Admin)" entries doesn't show a UAC prompt:

1. Regenerate the registry files with the latest script version
2. Make sure you applied the *new* generated file, not an old one
3. Restart Explorer: `taskkill /f /im explorer.exe; start explorer`

### Tools Show in Menu But Don't Work

This happens if a tool was uninstalled or moved after generating the registry file. Solution:

```powershell
# Regenerate to detect current state
.\Generate-ContextMenu.ps1
```

The script will only include tools it can actually find.

### Menu Entries Appear in Wrong Order

Windows sorts entries alphabetically by default. The numeric prefixes (`00`, `01`, `02`) override this. If entries are out of order:

1. Check that the prefixes are in the registry (open `regedit` and look at the key names)
2. If they're missing, reapply the generated file
3. Restart Explorer

### Context Menu Changes Don't Appear

Registry changes don't always take effect immediately:

```powershell
# Nuclear option - restart Explorer
taskkill /f /im explorer.exe
start explorer

# If that doesn't work, log off and back on
# Or restart Windows
```

## Technical Details

### Why PowerShell for Admin Elevation?

Direct registry commands with admin elevation are tricky. We use PowerShell's `Start-Process -Verb RunAs` as a wrapper because:

- It reliably triggers UAC prompts
- It properly passes the directory path to the elevated process
- The `-WindowStyle Hidden` flag prevents a flash of the intermediate PowerShell window

### Path Escaping Rules

Registry files require backslashes to be escaped (`\\`). The script's `ConvertTo-RegPath` function doubles them automatically, so:

```
C:\Program Files\Tool → C:\\Program Files\\Tool (in .reg file)
```

### Why Numeric Prefixes?

Windows sorts context menu entries alphabetically by the registry key name. Using `00Terminal`, `01MenuCmd`, etc. ensures your entries appear at the top in the order you want, regardless of what other software adds to the context menu.

### Why Submenus?

Without submenus, every option would appear in the main context menu, creating clutter. The `ExtendedSubCommandsKey` approach lets us:

- Keep the main menu clean (3-5 top-level items)
- Group related tools logically
- Make it easy to find what you need without hunting through 15+ entries

### Why Remove Default Windows Entries?

The default Windows entries (basic CMD and PowerShell options) still exist but are hidden behind Shift+Right-Click via the `Extended` flag. This:

- Reduces duplicate entries (we have better versions)
- Keeps the menu clean for everyday use
- Preserves the originals if you need them (Shift+Right-Click)

## Safety & Best Practices

### Registry Backups

Always back up before modifying the registry. The script generates an undo file automatically, but you can also:

```powershell
# Export current state manually
reg export HKEY_CLASSES_ROOT\Directory\shell backup-dir-shell.reg
reg export HKEY_CLASSES_ROOT\Directory\background\shell backup-dir-bg-shell.reg
```

### Testing on a VM

If you're concerned about system stability, test in a virtual machine first:

1. Spin up a Windows 10/11 VM
2. Install your tools (VS Code, Git, etc.)
3. Run the script and test functionality
4. Once confident, apply to your main system

### Version Control for Custom Modifications

If you customize the script:

1. Initialize git: `git init`
2. Commit the original: `git add . && git commit -m "Initial commit"`
3. Make your changes
4. Commit again: `git commit -am "Added custom tool X"`

This lets you track what you changed and revert if needed.

## Contributing

Found a bug? Have an idea for improvement? Contributions welcome:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly on Windows 10 and 11
5. Submit a pull request

## License

This project is provided as-is for personal and commercial use. Feel free to modify and distribute.

## Acknowledgments

Built for developers, sysadmins, and power users who want a context menu that actually makes sense.

---

**Tested on:** Windows 10 (21H2, 22H2) and Windows 11 (22H2, 23H2)  
**Last Updated:** November 2025
