@echo off
echo Monitoring deployment...

:: Check AWS CLI installation
aws --version > nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo AWS CLI is not installed. Please install it and configure your credentials.
    exit /b 1
)

:: Get the latest deployment ID
for /f "tokens=*" %%a in ('aws deploy list-deployments --application-name microservices-app --deployment-group-name microservices-deployment-group --query "deployments[0]" --output text') do set DEPLOYMENT_ID=%%a

if "%DEPLOYMENT_ID%"=="" (
    echo No active deployments found.
    exit /b 0
)

echo Monitoring deployment: %DEPLOYMENT_ID%

:MONITOR_LOOP
for /f "tokens=*" %%a in ('aws deploy get-deployment --deployment-id %DEPLOYMENT_ID% --query "deploymentInfo.status" --output text') do set DEPLOYMENT_STATUS=%%a

echo Deployment status: %DEPLOYMENT_STATUS%

if "%DEPLOYMENT_STATUS%"=="Succeeded" (
    echo Deployment completed successfully!
    goto :SHOW_LOGS
) else if "%DEPLOYMENT_STATUS%"=="Failed" (
    echo Deployment failed!
    goto :SHOW_LOGS
) else if "%DEPLOYMENT_STATUS%"=="Stopped" (
    echo Deployment was stopped.
    goto :SHOW_LOGS
) else (
    echo Waiting for deployment to complete...
    timeout /t 10 /nobreak > nul
    goto :MONITOR_LOOP
)

:SHOW_LOGS
echo Showing recent CloudWatch logs:
aws logs get-log-events --log-group-name /ecs/microservices --log-stream-name web/latest --limit 10

echo Deployment monitoring complete.
exit /b 0