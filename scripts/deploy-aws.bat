@echo off
echo Starting AWS deployment process...

:: Check AWS CLI installation
aws --version > nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo AWS CLI is not installed. Please install it and configure your credentials.
    exit /b 1
)

:: Navigate to project root
cd /d "%~dp0\.."

echo Logging in to Amazon ECR...
aws ecr get-login-password --region %AWS_REGION% | docker login --username AWS --password-stdin %AWS_ACCOUNT_ID%.dkr.ecr.%AWS_REGION%.amazonaws.com

echo Building and pushing Docker images to ECR...
for /d %%s in (services\*) do (
    echo Processing service: %%~ns
    
    :: Build the Docker image
    docker build -t %AWS_ACCOUNT_ID%.dkr.ecr.%AWS_REGION%.amazonaws.com/%%~ns:latest %%s
    
    :: Push the image to ECR
    docker push %AWS_ACCOUNT_ID%.dkr.ecr.%AWS_REGION%.amazonaws.com/%%~ns:latest
)

echo Updating ECS task definitions...
call scripts\update-task-definitions.bat

echo Starting blue/green deployment...
aws deploy create-deployment ^
    --application-name microservices-app ^
    --deployment-group-name microservices-deployment-group ^
    --revision revisionType=AppSpecContent,appSpecContent="{\"version\":1,\"Resources\":[{\"TargetService\":{\"Type\":\"AWS::ECS::Service\",\"Properties\":{\"TaskDefinition\":\"${TASK_DEFINITION_ARN}\",\"LoadBalancerInfo\":{\"ContainerName\":\"web\",\"ContainerPort\":80}}}}]}"

echo Deployment initiated. Use the following command to monitor the deployment:
echo scripts\monitor-deployment.bat

exit /b 0