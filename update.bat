@echo off
setlocal
rem ================================================================
rem  AI-Movie-Shorts  -  update.bat  -  double-click to update
rem
rem  1. Downloads the latest code from GitHub
rem  2. Copies the new source files into this folder
rem  3. Installs Piper TTS + the 4 default voices if they are missing
rem  4. Tests Piper once with a short sentence
rem  5. Rebuilds movie_summary_cli.exe with MSYS2
rem
rem  It NEVER touches: config.json, movies\, scripts\, output\,
rem  tiktok_output\ or backgroundmusic\.  The window stays open
rem  when it finishes so you can read the result.
rem ================================================================

if "%~1"=="--run" goto :run
cmd /k call "%~f0" --run
exit /b

:run
title AI-Movie-Shorts Update
cd /d "%~dp0"
set "ROOT=%~dp0"
if "%ROOT:~-1%"=="\" set "ROOT=%ROOT:~0,-1%"
set "WORK=%ROOT%\_update_tmp"
set "MSYS2ROOT=F:\New folder (3)"
set "BASH=%MSYS2ROOT%\usr\bin\bash.exe"
set "PS=powershell -NoProfile -ExecutionPolicy Bypass -Command"
set "CURL=%SystemRoot%\System32\curl.exe"
set "CODE_URL=https://github.com/farmanshahid471-code/AI-Movie-Shorts/archive/refs/heads/arena/a8b45986-ai-movie-shorts.zip"
set "PIPER_URL=https://github.com/rhasspy/piper/releases/download/2023.11.14-2/piper-2023.11.14-2-windows-x64.zip"
set "VOICE_URL=https://huggingface.co/rhasspy/piper-voices/resolve/v1.0.0"
set "DEPFLAGS=-DCMAKE_POLICY_VERSION_MINIMUM=3.5"
if exist "F:\deps\raylib\." if exist "F:\deps\cjson\." set "DEPFLAGS=-DFETCHCONTENT_SOURCE_DIR_RAYLIB=/f/deps/raylib -DFETCHCONTENT_SOURCE_DIR_CJSON=/f/deps/cjson -DCMAKE_POLICY_VERSION_MINIMUM=3.5"

echo ================================================================
echo  AI-Movie-Shorts updater
echo  Project folder: %ROOT%
echo ================================================================
echo(

echo [1/7] Checking this folder...
set "ERRMSG=This is not the AI-Movie-Shorts folder. Put update.bat inside F:\AI-Movie-Shorts1 and run it from there."
if not exist "%ROOT%\src\generator.c" goto :fail
if not exist "%ROOT%\config.json" echo [WARN] config.json is missing - the program will need it later.
tasklist /FI "IMAGENAME eq movie_summary_cli.exe" 2>nul | findstr /I /C:"movie_summary_cli.exe" >nul
if not errorlevel 1 goto :fail_running
if exist "%WORK%" rmdir /s /q "%WORK%"
mkdir "%WORK%"
echo       Folder OK.
echo(

echo [2/7] Downloading the latest code from GitHub...
set "ERRMSG=Could not download the code zip from GitHub. Check your internet connection and try again."
call :dl "%CODE_URL%" "%WORK%\code.zip"
if errorlevel 1 goto :fail

echo [3/7] Unpacking and copying the new source files...
set "ERRMSG=Could not unpack code.zip - the download may be damaged. Run update.bat again."
%PS% "Expand-Archive -Force -LiteralPath '%WORK%\code.zip' -DestinationPath '%WORK%\code'"
if errorlevel 1 goto :fail
set "SRCDIR="
for /d %%D in ("%WORK%\code\*") do set "SRCDIR=%%D"
set "ERRMSG=The code zip did not contain the expected project folder."
if not defined SRCDIR goto :fail
set "ERRMSG=Copying the new src folder failed."
xcopy /E /I /Y "%SRCDIR%\src" "%ROOT%\src" >nul
if errorlevel 1 goto :fail
set "ERRMSG=Copying the new CMakeLists.txt failed."
copy /Y "%SRCDIR%\CMakeLists.txt" "%ROOT%\CMakeLists.txt" >nul
if errorlevel 1 goto :fail
if exist "%SRCDIR%\README.md" copy /Y "%SRCDIR%\README.md" "%ROOT%\README.md" >nul
if exist "%SRCDIR%\update.bat" copy /Y "%SRCDIR%\update.bat" "%ROOT%\update_new.bat" >nul
if not exist "%ROOT%\resources\ui.png" if exist "%SRCDIR%\resources" xcopy /E /I /Y "%SRCDIR%\resources" "%ROOT%\resources" >nul
echo       Source files updated. config.json and backgroundmusic were not touched.
echo(

echo [4/7] Checking Piper TTS...
if exist "%ROOT%\piper\piper.exe" goto :have_piper
echo       Installing Piper into the piper folder - one-time download.
mkdir "%ROOT%\piper" 2>nul
set "ERRMSG=Could not download the Piper zip from GitHub. Check your internet connection and try again."
call :dl "%PIPER_URL%" "%WORK%\piper.zip"
if errorlevel 1 goto :fail
set "ERRMSG=Could not unpack the Piper zip. Run update.bat again."
%PS% "Expand-Archive -Force -LiteralPath '%WORK%\piper.zip' -DestinationPath '%WORK%\piper_extract'"
if errorlevel 1 goto :fail
set "PIPERDIR="
%PS% "$f = Get-ChildItem -LiteralPath '%WORK%\piper_extract' -Recurse -Filter piper.exe -ErrorAction SilentlyContinue | Select-Object -First 1; if ($f) { Set-Content -LiteralPath '%WORK%\piperdir.txt' -Value $f.DirectoryName }"
if exist "%WORK%\piperdir.txt" set /p PIPERDIR=<"%WORK%\piperdir.txt"
set "ERRMSG=piper.exe was not found inside the downloaded Piper zip."
if not defined PIPERDIR goto :fail
xcopy /E /I /Y "%PIPERDIR%\*" "%ROOT%\piper\" >nul
set "ERRMSG=Copying piper.exe into the piper folder failed."
if not exist "%ROOT%\piper\piper.exe" goto :fail
:have_piper
if exist "%ROOT%\piper\espeak-ng-data\." goto :have_espeak
echo [WARN] piper\espeak-ng-data is missing. Piper audio may fail. Copy the espeak-ng-data folder next to piper.exe.
:have_espeak
echo       Piper ready: %ROOT%\piper\piper.exe
echo(

echo [5/7] Checking the 4 offline voices: English, Spanish, Chinese, Arabic...
if not exist "%ROOT%\piper_voices\." mkdir "%ROOT%\piper_voices"
set "ERRMSG=Download failed for the English voice en_US-joe-medium."
call :dl "%VOICE_URL%/en/en_US/joe/medium/en_US-joe-medium.onnx" "%ROOT%\piper_voices\en_US-joe-medium.onnx"
if errorlevel 1 goto :fail
set "ERRMSG=Download failed for en_US-joe-medium.onnx.json."
call :dl "%VOICE_URL%/en/en_US/joe/medium/en_US-joe-medium.onnx.json" "%ROOT%\piper_voices\en_US-joe-medium.onnx.json"
if errorlevel 1 goto :fail
set "ERRMSG=Download failed for the Spanish voice es_MX-claude-high."
call :dl "%VOICE_URL%/es/es_MX/claude/high/es_MX-claude-high.onnx" "%ROOT%\piper_voices\es_MX-claude-high.onnx"
if errorlevel 1 goto :fail
set "ERRMSG=Download failed for es_MX-claude-high.onnx.json."
call :dl "%VOICE_URL%/es/es_MX/claude/high/es_MX-claude-high.onnx.json" "%ROOT%\piper_voices\es_MX-claude-high.onnx.json"
if errorlevel 1 goto :fail
set "ERRMSG=Download failed for the Chinese voice zh_CN-huayan-medium."
call :dl "%VOICE_URL%/zh/zh_CN/huayan/medium/zh_CN-huayan-medium.onnx" "%ROOT%\piper_voices\zh_CN-huayan-medium.onnx"
if errorlevel 1 goto :fail
set "ERRMSG=Download failed for zh_CN-huayan-medium.onnx.json."
call :dl "%VOICE_URL%/zh/zh_CN/huayan/medium/zh_CN-huayan-medium.onnx.json" "%ROOT%\piper_voices\zh_CN-huayan-medium.onnx.json"
if errorlevel 1 goto :fail
set "ERRMSG=Download failed for the Arabic voice ar_JO-kareem-medium."
call :dl "%VOICE_URL%/ar/ar_JO/kareem/medium/ar_JO-kareem-medium.onnx" "%ROOT%\piper_voices\ar_JO-kareem-medium.onnx"
if errorlevel 1 goto :fail
set "ERRMSG=Download failed for ar_JO-kareem-medium.onnx.json."
call :dl "%VOICE_URL%/ar/ar_JO/kareem/medium/ar_JO-kareem-medium.onnx.json" "%ROOT%\piper_voices\ar_JO-kareem-medium.onnx.json"
if errorlevel 1 goto :fail
echo       All voices ready in %ROOT%\piper_voices
echo(

echo [6/7] Testing Piper voice synthesis...
if not exist "%ROOT%\piper_voices\en_US-joe-medium.onnx" goto :skip_smoke
echo This is a Piper voice test. > "%WORK%\smoke.txt"
set "ERRMSG=Piper test failed - piper.exe did not create a sound file. Check that piper.exe and espeak-ng-data sit together in the piper folder."
"%ROOT%\piper\piper.exe" --model "%ROOT%\piper_voices\en_US-joe-medium.onnx" --output_file "%WORK%\smoke.wav" < "%WORK%\smoke.txt"
if not exist "%WORK%\smoke.wav" goto :fail
for %%A in ("%WORK%\smoke.wav") do if %%~zA LSS 1000 goto :fail
echo       Piper works - it created a test sound file.
goto :smoke_done
:skip_smoke
echo [WARN] Skipped - no English voice file was found.
:smoke_done
echo(

echo [7/7] Rebuilding the program - the first build can take a few minutes...
set "ERRMSG=MSYS2 was not found. Expected bash.exe in F:\New folder (3)\usr\bin. If MSYS2 is in a different folder, edit the MSYS2ROOT line inside update.bat."
if not exist "%BASH%" goto :fail
set "MSYSTEM=MINGW64"
set "ERRMSG=The build failed. Read the error messages above. If they mention raylib or cJSON, make sure F:\deps\raylib and F:\deps\cjson exist, then run update.bat again."
"%BASH%" -lc "cd $(cygpath -u '%ROOT%') && cmake -S . -B build -G Ninja %DEPFLAGS% && cmake --build build"
if errorlevel 1 goto :fail
set "ERRMSG=The build finished but build\movie_summary_cli.exe was not found."
if not exist "%ROOT%\build\movie_summary_cli.exe" goto :fail
echo       Build OK: %ROOT%\build\movie_summary_cli.exe
echo(

echo ================================================================
echo  UPDATE FINISHED SUCCESSFULLY
echo ================================================================
echo  [OK] Code updated from GitHub - branch arena/a8b45986-ai-movie-shorts
echo  [OK] Build: build\movie_summary_cli.exe
echo  [OK] Piper: piper\piper.exe
echo  [OK] Voices: piper_voices
echo  [OK] config.json was not changed
echo  [OK] backgroundmusic was not changed
echo(
echo  To make a video now:
echo    1. Open the "MSYS2 MinGW 64" terminal
echo    2. cd /f/AI-Movie-Shorts1
echo    3. ./build/movie_summary_cli.exe
echo(
if exist "%ROOT%\update_new.bat" echo  Note: a newer update.bat was saved as update_new.bat. You can delete it, or replace update.bat with it after closing this window.
echo  You can close this window now.
goto :final

:fail_running
echo ================================================================
echo  UPDATE STOPPED - movie_summary_cli.exe is still running.
echo ================================================================
echo  Close the program first, then run update.bat again.
echo  You can close this window now.
goto :final

:fail
echo ================================================================
echo  UPDATE STOPPED - %ERRMSG%
echo ================================================================
echo  Your config.json, movies and backgroundmusic were not changed.
echo  Fix the problem above and run update.bat again.
echo  You can close this window now.

:final
echo(
echo  Finished at %DATE% %TIME%
if exist "%WORK%" rmdir /s /q "%WORK%" 2>nul
goto :eof

rem ----------------------------------------------------------------
rem  :dl URL FILE - downloads only when the file is not there yet.
rem  Returns 0 on success, 1 on failure. A failed download is
rem  deleted so the next run tries again.
rem ----------------------------------------------------------------
:dl
if exist "%~2" goto :dl_have
echo       downloading: %~nx2
if exist "%CURL%" goto :dl_curl
%PS% "[Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12; $ProgressPreference='SilentlyContinue'; Invoke-WebRequest -Uri '%~1' -OutFile '%~2'"
if errorlevel 1 goto :dl_fail
exit /b 0
:dl_curl
"%CURL%" -L --fail --retry 3 --connect-timeout 20 -o "%~2" "%~1"
if errorlevel 1 goto :dl_fail
exit /b 0
:dl_have
echo       already present: %~nx2
exit /b 0
:dl_fail
echo       [ERROR] download failed: %~1
if exist "%~2" del /q "%~2"
exit /b 1
