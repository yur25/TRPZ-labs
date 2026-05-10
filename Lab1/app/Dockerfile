FROM node:20-alpine
WORKDIR /usr/src/app

# Set environment to production
ENV NODE_ENV=production

# Install only production dependencies
COPY package*.json ./
RUN npm ci --omit=dev

# Copy application source code
COPY . .

# Change ownership to the built-in non-root node user
RUN chown -R node:node /usr/src/app

# Switch to non-root user
USER node

EXPOSE 5200

# Run migrations then start the server
CMD ["sh", "-c", "node migrations/migrate.js && node src/server.js"]
