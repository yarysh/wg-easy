# There's an issue with node:16-alpine.
# On Raspberry Pi, the following crash happens:

# #FailureMessage Object: 0x7e87753c
# #
# # Fatal error in , line 0
# # unreachable code
# #
# #
# #

FROM docker.io/library/node:17-alpine@sha256:0fd72c52a9cd4d0f862bec97778bb1e71705aa57699b0e2976152d2e434ce2f5 AS build_node_modules

# Copy Web UI
COPY src/ /app/
WORKDIR /app
RUN npm ci --production

# Copy build result to a new image.
# This saves a lot of disk space.
FROM docker.io/library/node:17-alpine@sha256:0fd72c52a9cd4d0f862bec97778bb1e71705aa57699b0e2976152d2e434ce2f5
COPY --from=build_node_modules /app /app

# Move node_modules one directory up, so during development
# we don't have to mount it in a volume.
# This results in much faster reloading!
#
# Also, some node_modules might be native, and
# the architecture & OS of your development machine might differ
# than what runs inside of docker.
RUN mv /app/node_modules /node_modules

# Enable this to run `npm run serve`
RUN npm i -g nodemon

# Install Linux packages
RUN apk add -U --no-cache \
  wireguard-tools \
  dumb-init \
  ip6tables

# Set Environment
ENV DEBUG=Server,WireGuard

# Run Web UI
WORKDIR /app
CMD ["/usr/bin/dumb-init", "node", "server.js"]
