@echo off
echo Estimating AWS costs for microservices deployment...

:: Check Python installation
python --version > nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo Python is not installed. Please install Python 3.x and try again.
    exit /b 1
)

:: Run the Python script with all arguments passed to this batch file
python scripts\estimate-costs.py %*

exit /b 0