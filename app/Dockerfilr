# Stage 1: Build the app
FROM node:18-alpine AS builder

WORKDIR /app
COPY package*.json ./
RUN npm install 
COPY . .

# Stage 2: Minimal runtime image
FROM node:18-alpine

WORKDIR /app
RUN addgroup -S appgroup && adduser -S appuser -G appgroup
COPY --from=builder /app /app
USER appuser

EXPOSE 3000
CMD ["node", "server.js"]
