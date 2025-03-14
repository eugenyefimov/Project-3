# Build stage
FROM node:16-alpine AS build

WORKDIR /app

COPY package*.json ./
RUN npm ci --only=production

COPY . .

# Production stage
FROM node:16-alpine

WORKDIR /app

COPY --from=build /app/node_modules ./node_modules
COPY --from=build /app/package*.json ./
COPY --from=build /app/dist ./dist

# Create a non-root user and switch to it
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001 -G nodejs

USER nodejs

# Health check
HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
  CMD wget -qO- http://localhost:3000/health || exit 1

EXPOSE 3000

CMD ["node", "dist/index.js"]