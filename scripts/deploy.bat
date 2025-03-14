@echo off
echo Starting deployment process...

:: Check if Docker is running
docker info > nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo Docker is not running. Please start Docker and try again.
    exit /b 1
)

:: Build and deploy services
echo Building and deploying services...

:: Navigate to project root
cd /d "%~dp0\.."

:: Build Docker images
docker-compose build

:: Start services
docker-compose up -d

echo Deployment completed successfully!