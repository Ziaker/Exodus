@echo off
setlocal
pushd "%~dp0..\.."
set "APPDATA=%CD%\captures\necropole-battle\dados"
if not exist "%APPDATA%" mkdir "%APPDATA%"
set "NECROPOLE_GODOT=%CD%\Godot_v4.7.2-stable_win64.exe"
if not "%~1"=="" set "NECROPOLE_GODOT=%~1"
if not exist "%NECROPOLE_GODOT%" (
    echo Informe o caminho do executavel do Godot como primeiro argumento.
    popd
    exit /b 1
)
"%NECROPOLE_GODOT%" --path "%CD%" --script res://prototypes/necropole-battle/prototipo.gd --log-file "%CD%\captures\necropole-battle\jogar.log" -- --jogar
set "NECROPOLE_RESULT=%errorlevel%"
popd
exit /b %NECROPOLE_RESULT%
