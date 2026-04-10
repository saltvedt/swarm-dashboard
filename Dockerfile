FROM node:20-alpine AS base
RUN apk add --no-cache --update tini lego curl
ENTRYPOINT ["/sbin/tini", "--"]
WORKDIR /home/node/app

FROM base AS dependencies
ENV NODE_ENV production
COPY package.json yarn.lock ./
RUN yarn install --production

# Build the legacy Elm 0.18 frontend on the native builder architecture so
# local ARM test-cluster VMs do not require x86 emulation.
FROM node:10.16.0-buster-slim AS elm-build
RUN npm install --unsafe-perm -g elm@latest-0.18.0 --silent
RUN sed -i 's|deb.debian.org/debian|archive.debian.org/debian|g; s|security.debian.org/debian-security|archive.debian.org/debian-security|g' /etc/apt/sources.list \
    && printf 'Acquire::Check-Valid-Until "false";\n' > /etc/apt/apt.conf.d/99archive \
    && apt-get -o Acquire::AllowInsecureRepositories=true -qq update \
    && apt-get install -y --no-install-recommends netbase ca-certificates \
    && rm -rf /var/lib/apt/lists/*
WORKDIR /home/node/app/elm-client
COPY ./elm-client/elm-package.json .
RUN elm package install -y
COPY ./elm-client/ /home/node/app/elm-client/
RUN elm make Main.elm --output=client/index.js

FROM base AS release
ENV LEGO_PATH=/lego-files
COPY --from=dependencies /home/node/app/node_modules node_modules
COPY --from=elm-build /home/node/app/elm-client/client/ client
COPY package.json package.json
COPY server server
COPY server.sh server.sh
COPY healthcheck.sh healthcheck.sh
COPY crontab /var/spool/cron/crontabs/root

ENV PORT=8080
# HEALTHCHECK --interval=60s --timeout=30s \
#   CMD sh healthcheck.sh

# Run under Tini
CMD ["sh", "server.sh"]
