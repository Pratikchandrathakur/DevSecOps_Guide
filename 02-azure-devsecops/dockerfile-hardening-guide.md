# Dockerfile Hardening Guide

## Hardened Baseline
```dockerfile
FROM node:20-alpine AS builder
WORKDIR /usr/src/app
COPY package*.json ./
RUN npm ci --only=production

FROM node:20-alpine AS runner
WORKDIR /usr/src/app
USER node
COPY --chown=node:node --from=builder /usr/src/app/node_modules ./node_modules
COPY --chown=node:node . .
EXPOSE 3000
CMD ["node", "server.js"]
```

## Required Practices
- Multi-stage builds
- Non-root runtime user
- Minimal base image
- Explicit dependency install process
- Use `.dockerignore` to reduce attack surface

## Optional Enhancements
- Distroless runtime
- Read-only root filesystem at runtime
- Healthcheck endpoint and Docker HEALTHCHECK
