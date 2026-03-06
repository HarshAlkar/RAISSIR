@echo off
echo =============================================
echo   CertiTrack Backend - PM2 Server Manager
echo =============================================
echo.
cd /d "%~dp0"
call pm2 startOrRestart ecosystem.config.js
call pm2 save
echo.
echo =============================================
echo  Server is running in the background!
echo  It will NOT stop when you close this window.
echo.
echo  Commands:
echo    pm2 logs certitrack-backend  (view logs)
echo    pm2 restart certitrack-backend  (restart)
echo    pm2 stop certitrack-backend  (stop)
echo =============================================
echo.
pause
