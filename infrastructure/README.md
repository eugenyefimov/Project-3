# Infrastructure Deployment

This directory contains CloudFormation templates for deploying the AWS infrastructure required for the containerized microservices application.

## Step 1: Deploy Network Infrastructure

First, deploy the network infrastructure including VPC, subnets, and security groups:

```bash
aws cloudformation create-stack \
  --stack-name microservices-network \
  --template-body file://network.yml \
  --capabilities CAPABILITY_IAM

