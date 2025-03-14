#!/bin/bash
set -e

# Configuration
STACK_PREFIX="microservices"
AWS_REGION=$(aws configure get region)
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

echo "Cleaning up microservices application resources..."

# Step 1: Delete CodeDeploy stack
echo "Deleting CodeDeploy stack..."
aws cloudformation delete-stack --stack-name ${STACK_PREFIX}-codedeploy
aws cloudformation wait stack-delete-complete --stack-name ${STACK_PREFIX}-codedeploy

# Step 2: Delete CodeBuild stack
echo "Deleting CodeBuild stack..."
aws cloudformation delete-stack --stack-name ${STACK_PREFIX}-codebuild
aws cloudformation wait stack-delete-complete --stack-name ${STACK_PREFIX}-codebuild

# Step 3: Delete ECS stack
echo "Deleting ECS stack..."
aws cloudformation delete-stack --stack-name ${STACK_PREFIX}-ecs
aws cloudformation wait stack-delete-complete --stack-name ${STACK_PREFIX}-ecs

# Step 4: Delete ECR repositories
echo "Deleting ECR repositories..."
# First, delete all images in the repositories
aws ecr batch-delete-image --repository-name service-a --image-ids "$(aws ecr list-images --repository-name service-a --query 'imageIds[*]' --output json)" || true
aws ecr batch-delete-image --repository-name service-b --image-ids "$(aws ecr list-images --repository-name service-b --query 'imageIds[*]' --output json)" || true

# Then delete the ECR stack
aws cloudformation delete-stack --stack-name ${STACK_PREFIX}-ecr
aws cloudformation wait stack-delete-complete --stack-name ${STACK_PREFIX}-ecr

# Step 5: Delete network stack
echo "Deleting network stack..."
aws cloudformation delete-stack --stack-name ${STACK_PREFIX}-network
aws cloudformation wait stack-delete-complete --stack-name ${STACK_PREFIX}-network

# Step 6: Delete CloudWatch log groups
echo "Deleting CloudWatch log groups..."
aws logs delete-log-group --log-group-name /ecs/service-a || true
aws logs delete-log-group --log-group-name /ecs/service-b || true
aws logs delete-log-group --log-group-name /aws/codebuild/${STACK_PREFIX}-build || true

echo "Cleanup complete! All resources have been removed."

