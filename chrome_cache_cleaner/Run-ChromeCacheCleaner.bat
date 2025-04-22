@echo off
echo Chrome Onbellek Temizleyici baslatiliyor...
echo.

powershell.exe -ExecutionPolicy Bypass -File "%~dp0Clean-ChromeCache.ps1" -WaitForKeyPress

echo.
echo Islem tamamlandi.
pause 