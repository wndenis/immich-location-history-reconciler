# syntax=docker/dockerfile:1

# ---- Build stage ----
FROM node:20-alpine AS build
WORKDIR /app

# Enable pnpm via corepack, matching the CI workflow
RUN corepack enable && corepack prepare pnpm@latest --activate

# Install dependencies first (better layer caching)
COPY package.json pnpm-lock.yaml ./
RUN pnpm install --frozen-lockfile

# Copy the rest of the source and build
COPY . .

# Base URL for the static build. Defaults to "/" for standalone Docker use;
# override with --build-arg NUXT_APP_BASE_URL=/immich-location-history-reconciler/
# if you want to mirror the GitHub Pages deployment exactly.
ARG NUXT_APP_BASE_URL=/
ENV NUXT_APP_BASE_URL=${NUXT_APP_BASE_URL}

RUN pnpm exec nuxt build --preset github_pages

# ---- Runtime stage ----
FROM nginx:1.27-alpine AS runtime

COPY --from=build /app/.output/public /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf
