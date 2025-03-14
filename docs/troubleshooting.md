# Troubleshooting Guide

This guide provides solutions for common issues you might encounter during the deployment process.

## Local Development Issues

### Docker Compose Fails to Start

**Symptoms:**
- Error messages when running `deploy-local.bat`
- Services fail to start

**Solutions:**
1. Check if Docker Desktop is running
2. Verify port availability:
   ```bash
   netstat -ano | findstr :80
   netstat -ano | findstr :3000

3. Check Docker logs:
### API Service Not Accessible
Symptoms:

- Web frontend shows "Error" when loading data
- Cannot access API endpoints
Solutions:

1. Check if the API container is running:
   ```bash
   docker ps | findstr api
    ```
2. Check API logs:
   ```bash
   docker logs project-3_api_1
    ```
3. Verify network connectivity between containers:
## AWS Deployment Issues
### Infrastructure Creation Fails
Symptoms:

- CloudFormation stack creation fails
- Error messages in AWS console
Solutions:

1. Check CloudFormation events:
2. Verify IAM permissions
3. Check for resource limits in your AWS account
### Docker Image Push Fails
Symptoms:

- Error when pushing images to ECR
- Deployment script fails at the image push stage
Solutions:

1. Verify ECR repository exists:
2. Check ECR authentication:
3. Check Docker build logs
### ECS Service Fails to Start
Symptoms:

- ECS service shows 0 running tasks
- Service events indicate task failures
Solutions:

1. Check ECS service events:
2. Check CloudWatch logs:
   ```bash
   aws logs get-log-events --log-group-name /ecs/microservices --log-stream-name api/latest
    ```
   ```
3. Verify task definition:
   ```bash
   aws ecs describe-task-definition --task-definition microservices-task
    ```
   ```
### Load Balancer Health Checks Failing
Symptoms:

- Target group shows unhealthy targets
- Cannot access application via load balancer
Solutions:

1. Check target group health:
   ```bash
   aws elbv2 describe-target-health --target-group-arn %TARGET_GROUP_ARN%
    ```
   ```
2. Verify health check configuration
3. Check security group rules allow health check traffic
## CI/CD Pipeline Issues
### CodeBuild Failures
Symptoms:

- Build fails in AWS CodeBuild
- Error messages in build logs
Solutions:

1. Check CodeBuild logs
2. Verify buildspec.yml syntax
3. Check IAM permissions for CodeBuild service role
### CodeDeploy Failures
Symptoms:

- Deployment fails or rolls back
- Error messages in deployment logs
Solutions:

1. Check CodeDeploy events:
2. Verify appspec.yml syntax
3. Check ECS service configuration
## Monitoring and Maintenance
### High CPU/Memory Usage
Symptoms:

- CloudWatch alarms triggering
- Application performance degradation
Solutions:

1. Scale up ECS service:
   ```bash
   aws ecs update-service --cluster microservices-cluster --service microservices-service --desired-count 2
    ```
   ```
2. Optimize container resource usage
3. Check for memory leaks or inefficient code
### Unexpected AWS Costs
Symptoms:

- Higher than expected AWS bill
Solutions:

1. Check AWS Cost Explorer
2. Verify all resources are properly cleaned up
3. Set up AWS Budgets for cost monitoring