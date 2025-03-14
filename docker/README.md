# Docker Configuration

This directory contains Docker configuration files for each microservice in the application.

## Step 1: Create Dockerfiles for Each Service

### Service A Dockerfile

Create a Dockerfile for Service A:

```dockerfile
FROM node:16-alpine

WORKDIR /usr/src/app

COPY package*.json ./
RUN npm install

COPY . .

EXPOSE 3000
CMD ["npm", "start"]

