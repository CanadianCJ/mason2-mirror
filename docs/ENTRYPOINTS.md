# Mason2 Entrypoints

## Canonical Entrypoint
- `Start_Mason2.ps1`

This is the only authoritative startup logic for Mason2 stacks.

## Supported Wrappers
- `tools/launch/Start_Mason_FullStack.ps1`
- `tools/launch/Start_Mason_CoreOnly.ps1`
- `tools/launch/Launch_Doctor.ps1`
- `tools/launch/Create_Mason_Shortcuts.ps1`

Wrappers delegate to `Start_Mason2.ps1` and provide launcher logs, shortcuts, and diagnostics.

## Deprecated Legacy Launchers
Legacy launch scripts were quarantined to:
- `archives/legacy_launch/20260227_111342/`

Archived files:
- `Start_All.ps1`
- `Stop_All.ps1`
- `Start_Stack.ps1`
- `Start-MasonStack.ps1`
- `Start_Mason_Onyx_Stack.ps1`
- `Start_Mason_Onyx_Stack.Legacy.ps1`

Do not call archived launchers directly.
