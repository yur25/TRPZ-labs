# Stage 1: Build & Dependencies
FROM node:20-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci

# Stage 2: Production
FROM node:20-alpine
WORKDIR /usr/src/app
ENV NODE_ENV=production
ENV APP_HOST=0.0.0.0
COPY --from=builder /app/package*.json ./
RUN npm ci --omit=dev
COPY . .
RUN chown -R node:node /usr/src/app
USER node

EXPOSE 5200

# Run migrations then start the server
CMD ["sh", "-c", "node migrations/migrate.js && node src/server.js"]
