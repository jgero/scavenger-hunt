# This stage builds the sapper application.
FROM node:10 AS app-builder
WORKDIR /app
COPY . .
RUN npm install --no-audit --unsafe-perm
RUN npm run build

# This stage installs the runtime dependencies.
FROM node:10 AS runtime-builder
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci --production --unsafe-perm

# This stage only needs the compiled Sapper application
# and the runtime dependencies.
FROM node:10-alpine
WORKDIR /app
COPY --from=app-builder /app/__sapper__ ./__sapper__
COPY --from=app-builder /app/static ./static
COPY --from=runtime-builder /app/node_modules ./node_modules

EXPOSE 3000
CMD ["node", "__sapper__/build"]
