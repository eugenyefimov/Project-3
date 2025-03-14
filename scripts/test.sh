#!/bin/bash
set -e

# Configuration
STACK_PREFIX="microservices"

echo "Testing microservices application..."

# Step 1: Get the application URL
ALB_DNS=$(aws cloudformation describe-stacks --stack-name ${STACK_PREFIX}-ecs --query "Stacks[0].Outputs[?OutputKey=='LoadBalancerDNS'].OutputValue" --output text)

# Step 2: Test Service A
echo "Testing Service A..."
SERVICE_A_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" http://${ALB_DNS}/service-a/health)
if [ "$SERVICE_A_RESPONSE" -eq 200 ]; then
  echo "Service A is healthy (HTTP 200)"
else
  echo "Service A is not healthy (HTTP ${SERVICE_A_RESPONSE})"
  echo "Checking Service A logs..."
  aws logs get-log-events --log-group-name /ecs/service-a --log-stream-name $(aws logs describe-log-streams --log-group-name /ecs/service-a --query "logStreams[0].logStreamName" --output text) --limit 10
fi

# Step 3: Test Service B
echo "Testing Service B..."
SERVICE_B_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" http://${ALB_DNS}/service-b/health)
if [ "$SERVICE_B_RESPONSE" -eq 200 ]; then
  echo "Service B is healthy (HTTP 200)"
else
  echo "Service B is not healthy (HTTP ${SERVICE_B_RESPONSE})"
  echo "Checking Service B logs..."
  aws logs get-log-events --log-group-name /ecs/service-b --log-stream-name $(aws logs describe-log-streams --log-group-name /ecs/service-b --query "logStreams[0].logStreamName" --output text) --limit 10
fi

# Step 4: Check ECS service status
echo "Checking ECS service status..."
aws ecs describe-services --cluster microservices-cluster --services service-a service-b --query "services[*].[serviceName,runningCount,desiredCount,status]" --output table

# Step 5: Check CloudWatch metrics
echo "Checking CloudWatch metrics..."
aws cloudwatch get-metric-statistics \
  --namespace AWS/ECS \
  --metric-name CPUUtilization \
  --dimensions Name=ClusterName,Value=microservices-cluster Name=ServiceName,Value=service-a \
  --start-time $(date -u -v-1H +%Y-%m-%dT%H:%M:%SZ) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%SZ) \
  --period 300 \
  --statistics Average \
  --output table

aws cloudwatch get-metric-statistics \
  --namespace AWS/ECS \
  --metric-name CPUUtilization \
  --dimensions Name=ClusterName,Value=microservices-cluster Name=ServiceName,Value=service-b \
  --start-time $(date -u -v-1H +%Y-%m-%dT%H:%M:%SZ) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%SZ) \
  --period 300 \
  --statistics Average \
  --output table

echo "Testing complete!"

