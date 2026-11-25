# Multi-stage production Dockerfile for E-Health Monitoring App (API + Web + SQLite).
# Serves the React web portal at `/` and the Express REST API at `/api/v1/*` on one port.

FROM node:24-slim AS base
ENV PNPM_HOME="/pnpm"
ENV PATH="$PNPM_HOME:$PATH"
RUN corepack enable && corepack prepare pnpm@10.30.3 --activate
WORKDIR /app

# Stage 1: install workspace dependencies & build API + Web
FROM base AS builder
# Build tools required for compiling native better-sqlite3 on Linux
RUN apt-get update && apt-get install -y --no-install-recommends python3 make g++ && rm -rf /var/lib/apt/lists/*

COPY package.json pnpm-lock.yaml pnpm-workspace.yaml tsconfig.base.json ./
COPY packages/types/package.json packages/types/
COPY api/package.json api/
COPY web/package.json web/
RUN pnpm install --frozen-lockfile

COPY packages/types packages/types
COPY api api
COPY web web

ARG VITE_API_URL=/api/v1
ENV VITE_API_URL=$VITE_API_URL
RUN pnpm --filter @ehealth/api build && pnpm --filter @ehealth/web build

# Prune devDependencies for a smaller runtime image
RUN pnpm prune --prod

# Stage 2: lean runtime container
FROM node:24-slim AS runner
WORKDIR /app

ENV NODE_ENV=production
ENV PORT=3000
ENV DB_FILE=/data/ehealth.db
ENV WEB_DIST_DIR=/app/web/dist

COPY --from=builder /app/package.json /app/pnpm-workspace.yaml ./
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/packages/types/package.json ./packages/types/
COPY --from=builder /app/api/package.json ./api/
COPY --from=builder /app/api/node_modules ./api/node_modules
COPY --from=builder /app/api/dist ./api/dist
COPY --from=builder /app/api/drizzle ./api/drizzle
COPY --from=builder /app/web/dist ./web/dist

RUN mkdir -p /data
VOLUME ["/data"]
EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD node -e "fetch('http://127.0.0.1:' + (process.env.PORT || 3000) + '/api/v1/health').then(r => process.exit(r.ok ? 0 : 1)).catch(() => process.exit(1))"

CMD ["node", "api/dist/server.js"]
