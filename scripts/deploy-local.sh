#!/bin/bash

echo "Starting local deployment process..."

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "Docker is not running. Please start Docker and try again."
    exit 1
fi

# Build and deploy services
echo "Building and deploying services locally..."

# Navigate to project root
cd "$(dirname "$0")/.."

# Build Docker images
docker-compose -f docker-compose.local.yml build

# Start services
docker-compose -f docker-compose.local.yml up -d

echo "Local deployment completed successfully!"
echo "You can access your services at http://localhost"