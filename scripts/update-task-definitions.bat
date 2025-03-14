@echo off
echo Updating ECS task definitions...

:: Check AWS CLI installation
aws --version > nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo AWS CLI is not installed. Please install it and configure your credentials.
    exit /b 1
)

:: Get the current task definition
for /f "tokens=*" %%a in ('aws ecs describe-task-definition --task-definition microservices-task --query "taskDefinition.taskDefinitionArn" --output text') do set TASK_DEFINITION_ARN=%%a

if "%TASK_DEFINITION_ARN%"=="" (
    echo Creating new task definition...
    
    :: Create a new task definition
    aws ecs register-task-definition ^
        --family microservices-task ^
        --execution-role-arn %ECS_EXECUTION_ROLE_ARN% ^
        --task-role-arn %ECS_TASK_ROLE_ARN% ^
        --network-mode awsvpc ^
        --requires-compatibilities FARGATE ^
        --cpu 256 ^
        --memory 512 ^
        --container-definitions "[{\"name\":\"api\",\"image\":\"%AWS_ACCOUNT_ID%.dkr.ecr.%AWS_REGION%.amazonaws.com/api:latest\",\"essential\":true,\"portMappings\":[{\"containerPort\":3000,\"hostPort\":3000,\"protocol\":\"tcp\"}],\"logConfiguration\":{\"logDriver\":\"awslogs\",\"options\":{\"awslogs-group\":\"/ecs/microservices\",\"awslogs-region\":\"%AWS_REGION%\",\"awslogs-stream-prefix\":\"api\"}}},{\"name\":\"web\",\"image\":\"%AWS_ACCOUNT_ID%.dkr.ecr.%AWS_REGION%.amazonaws.com/web:latest\",\"essential\":true,\"portMappings\":[{\"containerPort\":80,\"hostPort\":80,\"protocol\":\"tcp\"}],\"logConfiguration\":{\"logDriver\":\"awslogs\",\"options\":{\"awslogs-group\":\"/ecs/microservices\",\"awslogs-region\":\"%AWS_REGION%\",\"awslogs-stream-prefix\":\"web\"}}}]"
) else (
    echo Updating existing task definition...
    
    :: Get the current task definition JSON
    aws ecs describe-task-definition --task-definition microservices-task --query "taskDefinition" > task-definition.json
    
    :: Update the container images
    aws ecs register-task-definition ^
        --cli-input-json file://task-definition.json
    
    :: Clean up
    del task-definition.json
)

:: Get the latest task definition ARN
for /f "tokens=*" %%a in ('aws ecs describe-task-definition --task-definition microservices-task --query "taskDefinition.taskDefinitionArn" --output text') do set NEW_TASK_DEFINITION_ARN=%%a

echo Task definition updated: %NEW_TASK_DEFINITION_ARN%
echo Setting environment variable TASK_DEFINITION_ARN=%NEW_TASK_DEFINITION_ARN%
setx TASK_DEFINITION_ARN %NEW_TASK_DEFINITION_ARN%

exit /b 0