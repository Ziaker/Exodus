$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
$enginePath = Join-Path $projectRoot 'Godot_v4.7.2-stable_win64.exe'
Start-Process -FilePath $enginePath -WorkingDirectory $projectRoot -ArgumentList @('--path', '.', '--resolution', '1088x832', 'res://scenes/battle/BattlePlayable.tscn')
