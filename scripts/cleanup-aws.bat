@echo off
echo AWS Resource Cleanup
echo ===================
echo.
echo This script will delete all AWS resources created for the microservices project.
echo WARNING: This action cannot be undone. All deployed services will be terminated.
echo.
set /p CONFIRM=Are you sure you want to proceed? (y/n): 

if /i not "%CONFIRM%"=="y" (
    echo Cleanup cancelled.
    exit /b 0
)

echo.
echo Starting cleanup process...
echo.

:: Check AWS CLI installation
aws --version > nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo AWS CLI is not installed. Please install it and configure your credentials.
    exit /b 1
)

:: Delete CloudWatch alarms
echo Deleting CloudWatch alarms...
aws cloudwatch delete-alarms --alarm-names high-cpu-utilization high-memory-utilization

:: Delete CloudWatch dashboard
echo Deleting CloudWatch dashboard...
aws cloudwatch delete-dashboards --dashboard-names microservices-dashboard

:: Update ECS service to 0 tasks
echo Scaling down ECS service...
aws ecs update-service --cluster microservices-cluster --service microservices-service --desired-count 0

:: Wait for tasks to stop
echo Waiting for tasks to stop...
timeout /t 30 /nobreak

:: Delete ECS service
echo Deleting ECS service...
aws ecs delete-service --cluster microservices-cluster --service microservices-service --force

:: Delete task definitions
echo Deleting task definitions...
for /f "tokens=*" %%a in ('aws ecs list-task-definitions --family-prefix microservices --query "taskDefinitionArns" --output text') do (
    echo Deregistering task definition: %%a
    aws ecs deregister-task-definition --task-definition %%a
)

:: Delete ECS cluster
echo Deleting ECS cluster...
aws ecs delete-cluster --cluster microservices-cluster

:: Delete target groups
echo Deleting target groups...
for /f "tokens=*" %%a in ('aws elbv2 describe-target-groups --names microservices-tg --query "TargetGroups[0].TargetGroupArn" --output text') do (
    echo Deleting target group: %%a
    aws elbv2 delete-target-group --target-group-arn %%a
)

:: Delete load balancer
echo Deleting load balancer...
for /f "tokens=*" %%a in ('aws elbv2 describe-load-balancers --names microservices-lb --query "LoadBalancers[0].LoadBalancerArn" --output text') do (
    echo Deleting load balancer: %%a
    aws elbv2 delete-load-balancer --load-balancer-arn %%a
)

:: Wait for load balancer to be deleted
echo Waiting for load balancer to be deleted...
timeout /t 60 /nobreak

:: Delete ECR repositories
echo Deleting ECR repositories...
aws ecr delete-repository --repository-name api --force
aws ecr delete-repository --repository-name web --force

:: Delete CloudFormation stacks
echo Deleting CloudFormation stacks...
aws cloudformation delete-stack --stack-name microservices-cicd
aws cloudformation delete-stack --stack-name microservices-ecs-cluster
aws cloudformation delete-stack --stack-name microservices-network

echo.
echo Cleanup process initiated. Some resources may take a few minutes to be fully deleted.
echo Please check the AWS Management Console to verify all resources have been properly removed.
echo.
echo To check the status of CloudFormation stack deletion:
echo aws cloudformation describe-stacks --stack-name microservices-network
echo.

exit /b 0