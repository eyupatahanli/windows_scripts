@echo off
setlocal enabledelayedexpansion

echo Chrome onbellek temizleyici baslatiliyor...
echo.

REM Chrome'un çalışıp çalışmadığını kontrol et ve kullanıcıları listele
echo Chrome calisan kullanicilar kontrol ediliyor...
echo.
set "chrome_users="
for /f "tokens=2" %%a in ('tasklist /FI "IMAGENAME eq chrome.exe" /FO CSV /NH') do (
    for /f "tokens=*" %%b in ('dir /b /s "%%a" ^| findstr /i "Users"') do (
        for /f "tokens=3" %%c in ('echo %%b ^| findstr /r /c:"Users\\[^\\]*\\"') do (
            set "chrome_users=!chrome_users! %%c"
            echo UYARI: %%c kullanicisinin Chrome'u calisiyor.
        )
    )
)

if not "%chrome_users%"=="" (
    echo.
    echo Not: Chrome calisan kullanicilar atlanacak.
    echo.
    timeout /t 5
)

powershell -ExecutionPolicy Bypass -File "%~dp0Clean-ChromeCache.ps1" -WaitForKeyPress

echo.
echo Islem tamamlandi.
pause 