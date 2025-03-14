@echo off
echo Verifying AWS deployment...

:: Check AWS CLI installation
aws --version > nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo AWS CLI is not installed. Please install it and configure your credentials.
    exit /b 1
)

:: Get the load balancer DNS name
for /f "tokens=*" %%a in ('aws elbv2 describe-load-balancers --names microservices-lb --query "LoadBalancers[0].DNSName" --output text') do set LB_DNS=%%a

if "%LB_DNS%"=="" (
    echo Load balancer not found. Please make sure the infrastructure is set up correctly.
    exit /b 1
)

echo Load Balancer DNS: %LB_DNS%

:: Check ECS service status
echo Checking ECS service status...
aws ecs describe-services --cluster microservices-cluster --services microservices-service --query "services[0].{Status:status,DesiredCount:desiredCount,RunningCount:runningCount}" --output table

:: Check target group health
echo Checking target group health...
for /f "tokens=*" %%a in ('aws elbv2 describe-target-groups --names microservices-tg --query "TargetGroups[0].TargetGroupArn" --output text') do set TG_ARN=%%a

if "%TG_ARN%"=="" (
    echo Target group not found. Please make sure the infrastructure is set up correctly.
    exit /b 1
)

aws elbv2 describe-target-health --target-group-arn %TG_ARN% --query "TargetHealthDescriptions[].{TargetId:Target.Id,Status:TargetHealth.State,Reason:TargetHealth.Reason}" --output table

:: Check if the application is accessible
echo Checking application accessibility...
curl -s -o nul -w "HTTP Status: %%{http_code}\n" http://%LB_DNS%/

:: Check API health
echo Checking API health...
curl -s -o nul -w "API Health Check: %%{http_code}\n" http://%LB_DNS%/api/health

:: Check CloudWatch logs
echo Checking recent CloudWatch logs...
aws logs get-log-events --log-group-name /ecs/microservices --log-stream-name web/latest --limit 5 --query "events[].{Timestamp:timestamp,Message:message}" --output table

echo Deployment verification completed!
echo.
echo Your application is available at: http://%LB_DNS%/
echo.
echo Next steps:
echo 1. Set up monitoring: .\scripts\setup-monitoring.bat
echo 2. Configure CI/CD pipeline: Follow instructions in docs\deployment-guide.md
echo 3. Implement security best practices: See docs\security-best-practices.md
echo.

exit /b 0