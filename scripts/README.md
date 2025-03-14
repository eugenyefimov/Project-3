# Deployment and Testing Scripts

This directory contains utility scripts for deploying and testing your containerized microservices on AWS.

## Deployment Scripts

### Step 1: Local Docker Deployment

For local testing before AWS deployment:

For Linux/Mac users, use the `deploy-local.sh` script:
```bash
./deploy-local.sh
```

For Windows users, use the `deploy.bat` script:
```bash
.\deploy.bat
```

Remember to make the deploy.sh file executable if you're using it on Linux/Mac systems:
```bash
chmod +x scripts/deploy.sh
```