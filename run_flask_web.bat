@echo off
echo ============================================
echo   Starting Flask for Flutter Web (Chrome)
echo ============================================
echo.
echo Flask URL: http://localhost:5000
echo Flutter Web URL: http://localhost:8080 (or wherever flutter run serves)
echo.
echo IMPORTANT: Run Flutter with:
echo   flutter run -d chrome --web-browser-flag "--disable-web-security"
echo.
python app.py
pause
