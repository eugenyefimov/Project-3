@echo off
echo Setting up AWS infrastructure using CloudFormation...

:: Check AWS CLI installation
aws --version > nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo AWS CLI is not installed. Please install it and configure your credentials.
    exit /b 1
)

:: Navigate to project root
cd /d "%~dp0\.."

:: Deploy network infrastructure
echo Deploying network infrastructure (VPC, subnets, security groups)...
aws cloudformation deploy ^
    --template-file infrastructure/network.yml ^
    --stack-name microservices-network ^
    --capabilities CAPABILITY_IAM

:: Create ECR repositories
echo Creating ECR repositories...
for /d %%s in (services\*) do (
    echo Creating repository for service: %%~ns
    aws ecr create-repository --repository-name %%~ns --image-scanning-configuration scanOnPush=true
)

:: Set up ECS cluster
echo Setting up ECS cluster...
aws cloudformation deploy ^
    --template-file infrastructure/ecs-cluster.yml ^
    --stack-name microservices-ecs-cluster ^
    --capabilities CAPABILITY_IAM

:: Set up CodeBuild and CodeDeploy
echo Setting up CI/CD pipeline...
aws cloudformation deploy ^
    --template-file infrastructure/cicd.yml ^
    --stack-name microservices-cicd ^
    --capabilities CAPABILITY_IAM

echo AWS infrastructure setup completed successfully!
exit /b 0