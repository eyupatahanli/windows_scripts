@echo off
echo Chrome onbellek temizleyici baslatiliyor...
echo.

REM Chrome'un çalışıp çalışmadığını kontrol et
tasklist /FI "IMAGENAME eq chrome.exe" 2>NUL | find /I /N "chrome.exe">NUL
if "%ERRORLEVEL%"=="0" (
    echo UYARI: Chrome calisiyor. Lutfen Chrome'u kapatip tekrar deneyin.
    echo.
    pause
    exit /b 1
)

powershell -ExecutionPolicy Bypass -File "%~dp0Clean-ChromeCache.ps1" -WaitForKeyPress

echo.
echo Islem tamamlandi.
pause 