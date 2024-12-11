# ---- Backend Builder ----
FROM node:22-alpine AS backend-builder

WORKDIR /source

RUN id

COPY package.json yarn.lock ./source
RUN yarn install --frozen-lockfile && du -sh node_modules/*

COPY . .
RUN yarn db:push && yarn build && du -sh dist/*

RUN rm -rf node_modules && yarn install --frozen-lockfile --production && du -sh node_modules/*


# ---- Frontend Builder ----
FROM node:22-alpine AS frontend-builder

WORKDIR /source

COPY /ui/package.json ui/yarn.lock ./source
RUN yarn install --frozen-lockfile

COPY /ui .
RUN yarn build && du -sh .next/*

# ---- Release image ----

FROM node:22-alpine

WORKDIR /app
COPY --chown=node:node --from=backend-builder /source/dist  .
COPY --chown=node:node --from=backend-builder /source/node_modules  .

COMMAND ["node", "dist/app.js"]