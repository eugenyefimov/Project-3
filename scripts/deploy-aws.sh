#!/bin/bash

echo "Starting AWS deployment process..."

# Check AWS CLI installation
if ! aws --version > /dev/null 2>&1; then
    echo "AWS CLI is not installed. Please install it and configure your credentials."
    exit 1
fi

# Navigate to project root
cd "$(dirname "$0")/.."

echo "Logging in to Amazon ECR..."
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com

echo "Building and pushing Docker images to ECR..."
for service_dir in services/*/; do
    service_name=$(basename $service_dir)
    echo "Processing service: $service_name"
    
    # Build the Docker image
    docker build -t $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$service_name:latest $service_dir
    
    # Push the image to ECR
    docker push $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$service_name:latest
done

echo "Updating ECS task definitions..."
./scripts/update-task-definitions.sh

echo "Starting blue/green deployment..."
aws deploy create-deployment \
    --application-name microservices-app \
    --deployment-group-name microservices-deployment-group \
    --revision revisionType=AppSpecContent,appSpecContent="{\"version\":1,\"Resources\":[{\"TargetService\":{\"Type\":\"AWS::ECS::Service\",\"Properties\":{\"TaskDefinition\":\"${TASK_DEFINITION_ARN}\",\"LoadBalancerInfo\":{\"ContainerName\":\"web\",\"ContainerPort\":80}}}}]}"

echo "Deployment initiated. Use the following command to monitor the deployment:"
echo "./scripts/monitor-deployment.sh"

exit 0