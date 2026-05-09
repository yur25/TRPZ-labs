# Stage 1: Build & Install dependencies
FROM node:20-alpine AS builder
WORKDIR /usr/src/app

# Copy package files
COPY package*.json ./

# Install ALL dependencies
RUN npm ci

# Copy application source code
COPY . .

# Stage 2: Production runtime
FROM node:20-alpine AS production
WORKDIR /usr/src/app

# Set environment to production
ENV NODE_ENV=production

# Install only production dependencies
COPY package*.json ./
RUN npm ci --omit=dev

# Copy source from builder
COPY --from=builder /usr/src/app/src ./src
COPY --from=builder /usr/src/app/migrations ./migrations

# Change ownership to the built-in non-root node user
RUN chown -R node:node /usr/src/app

# Switch to non-root user
USER node

EXPOSE 5200

# Run migrations then start the server
CMD ["sh", "-c", "node migrations/migrate.js && node src/server.js"]
