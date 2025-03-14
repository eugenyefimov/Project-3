@echo off
echo Setting up CloudWatch monitoring...

:: Check AWS CLI installation
aws --version > nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo AWS CLI is not installed. Please install it and configure your credentials.
    exit /b 1
)

:: Get the load balancer ARN
for /f "tokens=*" %%a in ('aws elbv2 describe-load-balancers --names microservices-lb --query "LoadBalancers[0].LoadBalancerArn" --output text') do set LOAD_BALANCER_ARN=%%a

if "%LOAD_BALANCER_ARN%"=="" (
    echo Load balancer not found. Please make sure the infrastructure is set up correctly.
    exit /b 1
)

echo Load Balancer ARN: %LOAD_BALANCER_ARN%

:: Create a temporary dashboard file with the correct values
powershell -Command "(Get-Content infrastructure\cloudwatch-dashboard.json) -replace '\${AWS_REGION}', '%AWS_REGION%' -replace '\${LOAD_BALANCER_ARN}', '%LOAD_BALANCER_ARN%' | Set-Content dashboard-temp.json"

:: Create the CloudWatch dashboard
aws cloudwatch put-dashboard --dashboard-name microservices-dashboard --dashboard-body file://dashboard-temp.json

:: Clean up
del dashboard-temp.json

:: Create CloudWatch alarms
echo Creating CloudWatch alarms...

:: CPU Utilization Alarm
aws cloudwatch put-metric-alarm ^
    --alarm-name high-cpu-utilization ^
    --alarm-description "Alarm when CPU exceeds 80%%" ^
    --metric-name CPUUtilization ^
    --namespace AWS/ECS ^
    --statistic Average ^
    --period 60 ^
    --threshold 80 ^
    --comparison-operator GreaterThanThreshold ^
    --dimensions Name=ClusterName,Value=microservices-cluster Name=ServiceName,Value=microservices-service ^
    --evaluation-periods 1 ^
    --alarm-actions arn:aws:sns:%AWS_REGION%:%AWS_ACCOUNT_ID%:deployment-notifications

:: Memory Utilization Alarm
aws cloudwatch put-metric-alarm ^
    --alarm-name high-memory-utilization ^
    --alarm-description "Alarm when Memory exceeds 80%%" ^
    --metric-name MemoryUtilization ^
    --namespace AWS/ECS ^
    --statistic Average ^
    --period 60 ^
    --threshold 80 ^
    --comparison-operator GreaterThanThreshold ^
    --dimensions Name=ClusterName,Value=microservices-cluster Name=ServiceName,Value=microservices-service ^
    --evaluation-periods 1 ^
    --alarm-actions arn:aws:sns:%AWS_REGION%:%AWS_ACCOUNT_ID%:deployment-notifications

echo CloudWatch monitoring setup completed successfully!
exit /b 0