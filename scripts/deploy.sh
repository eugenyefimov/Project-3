#!/bin/bash

echo "Starting deployment process..."

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "Docker is not running. Please start Docker and try again."
    exit 1
fi

# Build and deploy services
echo "Building and deploying services..."

# Navigate to project root
cd "$(dirname "$0")/.."

# Build Docker images
docker-compose build

# Start services
docker-compose up -d

echo "Deployment completed successfully!"