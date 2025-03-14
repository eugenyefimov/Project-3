# Detailed Deployment Guide

This guide provides step-by-step instructions for deploying the containerized microservices to AWS.

## 1. Local Development and Testing

Before deploying to AWS, it's important to test your microservices locally:

1. **Build and run locally**:
   ```bash
   .\scripts\deploy-local.bat
   ```

2. **Test the application** at http://localhost

3. **Verify all services** are working correctly:
   - API service should respond at http://localhost/api/items
   - Web service should display the frontend interface

## 2. AWS Infrastructure Setup

Setting up the AWS infrastructure is the first step in the deployment process:

1. **Configure AWS credentials**:
   ```bash
   aws configure
   ```

2. **Create a .env file** with your AWS settings:
   ```bash
   copy .env.example .env
   ```
   Edit the .env file with your specific AWS account details.

3. **Set up the infrastructure**:
   ```bash
   .\scripts\setup-aws-infrastructure.bat
   ```

   This script will:
   - Create a VPC with public and private subnets
   - Set up security groups
   - Create an ECS cluster
   - Set up load balancers and target groups
   - Create ECR repositories for your Docker images

4. **Verify infrastructure creation**:
   ```bash
   aws cloudformation describe-stacks --stack-name microservices-network
   aws cloudformation describe-stacks --stack-name microservices-ecs-cluster
   ```

## 3. Docker Image Preparation

Proper Docker image preparation is crucial for efficient deployments:

1. **Multi-stage builds**:
   Our Dockerfiles use multi-stage builds to create optimized production images:

   ```dockerfile
   # Build stage
   FROM node:16-alpine AS build
   WORKDIR /app
   COPY package*.json ./
   RUN npm ci
   COPY . .
   RUN npm run build

   # Production stage
   FROM nginx:alpine
   COPY --from=build /app/build /usr/share/nginx/html
   COPY nginx.conf /etc/nginx/conf.d/default.conf
   EXPOSE 80
   CMD ["nginx", "-g", "daemon off;"]
   ```

   Benefits of multi-stage builds:
   - Smaller final image size
   - Only production dependencies included
   - Build tools excluded from final image
   - Improved security posture

2. **Build the Docker images**:
   ```bash
   docker build -t microservices/api:latest -f services/api/Dockerfile services/api
   docker build -t microservices/web:latest -f services/web/Dockerfile services/web
   ```

3. **Test the images locally**:
   ```bash
   docker run -p 3000:3000 microservices/api:latest
   docker run -p 80:80 microservices/web:latest
   ```

## 4. Deploying to AWS

Once the infrastructure is set up and images are prepared, you can deploy your microservices:

1. **Push Docker images to ECR**:
   ```bash
   aws ecr get-login-password --region %AWS_REGION% | docker login --username AWS --password-stdin %AWS_ACCOUNT_ID%.dkr.ecr.%AWS_REGION%.amazonaws.com
   
   docker tag microservices/api:latest %AWS_ACCOUNT_ID%.dkr.ecr.%AWS_REGION%.amazonaws.com/api:latest
   docker tag microservices/web:latest %AWS_ACCOUNT_ID%.dkr.ecr.%AWS_REGION%.amazonaws.com/web:latest
   
   docker push %AWS_ACCOUNT_ID%.dkr.ecr.%AWS_REGION%.amazonaws.com/api:latest
   docker push %AWS_ACCOUNT_ID%.dkr.ecr.%AWS_REGION%.amazonaws.com/web:latest
   ```

2. **Deploy the application**:
   ```bash
   .\scripts\deploy-aws.bat
   ```

   This script will:
   - Update ECS task definitions with the new image URIs
   - Update ECS services to use the new task definitions
   - Initiate a blue/green deployment

3. **Monitor the deployment**:
   ```bash
   aws ecs describe-services --cluster microservices-cluster --services microservices-service
   ```

4. **Verify the deployment**:
   ```bash
   .\scripts\verify-deployment.bat
   ```

5. **Access your application** using the load balancer DNS name provided in the verification output.

## 5. Blue/Green Deployment Strategy

This project implements a blue/green deployment strategy for zero-downtime updates:

1. **How it works**:
   - New version (green) is deployed alongside the existing version (blue)
   - Traffic is gradually shifted from blue to green
   - If issues are detected, traffic can be shifted back to blue
   - Once green is confirmed healthy, blue is decommissioned

2. **Implementation with AWS CodeDeploy**:
   ```bash
   aws deploy create-deployment \
     --application-name microservices-app \
     --deployment-group-name microservices-deployment-group \
     --revision revisionType=AppSpecContent,appSpecContent="{\"version\":1,\"Resources\":[{\"TargetService\":{\"Type\":\"AWS::ECS::Service\",\"Properties\":{\"TaskDefinition\":\"${TASK_DEFINITION_ARN}\",\"LoadBalancerInfo\":{\"ContainerName\":\"web\",\"ContainerPort\":80}}}}]}"
   ```

3. **Monitoring the deployment**:
   ```bash
   aws deploy get-deployment --deployment-id ${DEPLOYMENT_ID}
   ```

4. **Rolling back if necessary**:
   ```bash
   aws deploy stop-deployment --deployment-id ${DEPLOYMENT_ID}
   ```

## 6. Continuous Integration and Deployment

For automated CI/CD:

1. **Set up GitHub repository** with your code

2. **Create buildspec.yml** for AWS CodeBuild:
   ```yaml
   version: 0.2

   phases:
     pre_build:
       commands:
         - echo Logging in to Amazon ECR...
         - aws ecr get-login-password --region $AWS_DEFAULT_REGION | docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com
         - COMMIT_HASH=$(echo $CODEBUILD_RESOLVED_SOURCE_VERSION | cut -c 1-7)
         - IMAGE_TAG=${COMMIT_HASH:=latest}
     build:
       commands:
         - echo Building the Docker images...
         - docker build -t $AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com/api:$IMAGE_TAG -f services/api/Dockerfile services/api
         - docker build -t $AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com/web:$IMAGE_TAG -f services/web/Dockerfile services/web
     post_build:
       commands:
         - echo Pushing the Docker images...
         - docker push $AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com/api:$IMAGE_TAG
         - docker push $AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com/web:$IMAGE_TAG
         - echo Writing image definitions file...
         - aws ecs describe-task-definition --task-definition microservices-task --query taskDefinition > taskdef.json
         - envsubst < appspec-template.yml > appspec.yml

   artifacts:
     files:
       - appspec.yml
       - taskdef.json
   ```

3. **Configure AWS CodePipeline**:
   - Source: GitHub repository
   - Build: AWS CodeBuild project
   - Deploy: AWS CodeDeploy to ECS

4. **Set up deployment notifications**:
   ```bash
   aws sns create-topic --name deployment-notifications
   aws sns subscribe --topic-arn [TOPIC_ARN] --protocol email --notification-endpoint your-email@example.com
   ```

5. **Configure CodePipeline to use SNS**:
   ```bash
   aws codepipeline update-pipeline --cli-input-json file://pipeline-config.json
   ```

## 7. Monitoring and Maintenance

After deployment:

1. **Set up CloudWatch dashboard**:
   ```bash
   .\scripts\setup-monitoring.bat
   ```

2. **Monitor application performance**:
   ```bash
   aws cloudwatch get-dashboard --dashboard-name microservices-dashboard
   ```

3. **Check logs**:
   ```bash
   aws logs get-log-events --log-group-name /ecs/microservices --log-stream-name web/latest
   ```

4. **Set up alarms** for critical metrics:
   ```bash
   aws cloudwatch put-metric-alarm \
     --alarm-name high-cpu-utilization \
     --metric-name CPUUtilization \
     --namespace AWS/ECS \
     --statistic Average \
     --period 60 \
     --threshold 80 \
     --comparison-operator GreaterThanThreshold \
     --dimensions Name=ClusterName,Value=microservices-cluster \
     --evaluation-periods 1 \
     --alarm-actions [SNS_TOPIC_ARN]
   ```

5. **Implement auto-scaling**:
   ```bash
   aws application-autoscaling register-scalable-target \
     --service-namespace ecs \
     --scalable-dimension ecs:service:DesiredCount \
     --resource-id service/microservices-cluster/microservices-service \
     --min-capacity 1 \
     --max-capacity 5
   ```

## 8. Security Best Practices

Implement these security best practices:

1. **Enable ECR image scanning**:
   ```bash
   aws ecr put-image-scanning-configuration \
     --repository-name api \
     --image-scanning-configuration scanOnPush=true
   ```

2. **Implement least privilege IAM roles**:
   - Use separate roles for task execution and task runtime
   - Grant only necessary permissions

3. **Enable VPC Flow Logs**:
   ```bash
   aws ec2 create-flow-logs \
     --resource-type VPC \
     --resource-ids vpc-12345678 \
     --traffic-type ALL \
     --log-group-name VPCFlowLogs \
     --deliver-logs-permission-arn arn:aws:iam::123456789012:role/FlowLogsRole
   ```

4. **Enable AWS CloudTrail**:
   ```bash
   aws cloudtrail create-trail \
     --name microservices-trail \
     --s3-bucket-name microservices-cloudtrail-bucket
   ```

## 9. Cost Optimization

Implement these cost optimization strategies:

1. **Right-size ECS tasks**:
   - Start with minimal CPU and memory allocations
   - Monitor usage and adjust as needed

2. **Use Fargate Spot for non-critical workloads**:
   ```bash
   aws ecs update-service \
     --cluster microservices-cluster \
     --service microservices-service \
     --capacity-provider-strategy capacityProvider=FARGATE_SPOT,weight=1
   ```

3. **Implement ECR lifecycle policies**:
   ```bash
   aws ecr put-lifecycle-policy \
     --repository-name api \
     --lifecycle-policy-text file://lifecycle-policy.json
   ```

4. **Set CloudWatch log retention**:
   ```bash
   aws logs put-retention-policy \
     --log-group-name /ecs/microservices \
     --retention-in-days 14
   ```

## 10. Cleanup

When you're done with the deployment:

1. **Clean up all resources**:
   ```bash
   .\scripts\cleanup-aws.bat
   ```

2. **Verify deletion** of all resources to avoid unexpected charges:
   ```bash
   aws cloudformation list-stacks --stack-status-filter DELETE_COMPLETE
   ```

## Troubleshooting

If you encounter issues during deployment, refer to the [Troubleshooting Guide](troubleshooting.md) for solutions to common problems.

## Additional Resources

- [AWS ECS Documentation](https://docs.aws.amazon.com/ecs/)
- [Docker Multi-Stage Builds](https://docs.docker.com/build/building/multi-stage/)
- [AWS CodeDeploy Blue/Green Deployments](https://docs.aws.amazon.com/codedeploy/latest/userguide/welcome.html)
- [CloudWatch Monitoring](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/WhatIsCloudWatch.html)
- [AWS Cost Optimization](https://aws.amazon.com/aws-cost-management/)
```

This deployment guide provides comprehensive instructions for the entire containerized deployment workflow, including detailed sections on Docker image preparation with multi-stage builds, blue/green deployment strategy, CI/CD setup, monitoring, security best practices, and cost optimization. It covers all aspects of the deployment process from local development to production deployment and maintenance.