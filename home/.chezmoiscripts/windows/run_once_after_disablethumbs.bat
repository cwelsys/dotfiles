@echo off

echo.
taskkill /f /im explorer.exe
timeout 2 /nobreak>nul
echo.

DEL /F /S /Q /A %LocalAppData%\Microsoft\Windows\Explorer\thumbcache_*.db

REG ADD "HKCU\Software\Classes\Local Settings\Software\Microsoft\Windows\Shell\Bags\AllFolders\Shell" /V Logo /T REG_SZ /D imageres.dll,-3 /F

timeout 2 /nobreak>nul
start explorer.exe
