ARG BASE_IMAGE=docker.io/library/node:22-alpine

# ---- Backend Builder ----
FROM $BASE_IMAGE AS backend-builder
USER node
WORKDIR /home/node/source

# dependencies
COPY --chown=node:node package.json yarn.lock ./
RUN yarn install --frozen-lockfile && du -sh node_modules

# build
COPY --chown=node:node package.json tsconfig.json drizzle.config.ts ./
COPY --chown=node:node src ./src
RUN mkdir data uploads ui && yarn db:push && yarn build && du -sh dist

# cleanup
RUN rm -rf src node_modules && yarn install --frozen-lockfile --production && rm yarn.lock && du -sh node_modules


# ---- Frontend Builder ----

FROM $BASE_IMAGE AS frontend-builder
USER node
WORKDIR /home/node/source

# dependencies
COPY --chown=node:node package.json ui/package.json ui/yarn.lock ./
RUN yarn install --frozen-lockfile && du -sh node_modules

# build
COPY ui ./
RUN yarn build && du -sh .next/*

# prepare
RUN mv .next/static  .next/standalone/.next/static

# ---- Release image ----
FROM $BASE_IMAGE
USER node
WORKDIR /app
COPY --from=backend-builder /home/node/source ./
COPY --from=frontend-builder /home/node/source/.next/standalone ./ui


EXPOSE 3000
ENV PORT=3000
ENV HOSTNAME="0.0.0.0"

# Ref: https://github.com/vercel/next.js/blob/canary/examples/with-docker/Dockerfile
# server.js is created by next build from the standalone output
# https://nextjs.org/docs/pages/api-reference/next-config-js/output

# TODO: https://www.bekk.christmas/post/2022/13/how-to-create-a-simple-custom-server-in-next-js
# https://nextjs.org/docs/pages/building-your-application/configuring/custom-server

CMD ["node", "-e" , "require('./dist/app.js');require('./ui/server.js')"]



# stats
# /app $ du -sh /app/*  |  sort -h
# 4.0K    /app/drizzle.config.ts
# 4.0K    /app/package.json
# 4.0K    /app/tsconfig.json
# 4.0K    /app/uploads
# 20.0K   /app/data
# 276.0K  /app/dist
# 25.0M   /app/ui
# 513.5M  /app/node_modules
# /app $ 
