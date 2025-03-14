# CI/CD Pipeline Configuration

This directory contains configuration files for setting up a CI/CD pipeline using AWS CodeBuild and CodeDeploy.

## Step 1: Create CodeBuild Project

First, create a CodeBuild project to build and push your Docker images to ECR:

```bash
aws cloudformation create-stack \
  --stack-name microservices-codebuild \
  --template-body file://codebuild.yml \
  --capabilities CAPABILITY_IAM \
  --parameters \
    ParameterKey=GitHubOwner,ParameterValue=your-github-username \
    ParameterKey=GitHubRepo,ParameterValue=your-repo-name \
    ParameterKey=GitHubBranch,ParameterValue=main

