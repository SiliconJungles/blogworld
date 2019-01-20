FROM elixir:alpine AS builder

# The name of your application/release (required)
ARG APP_NAME

# The version of the application we are building (required)
ARG APP_VSN

# Set this to true if this release is not a Phoenix app
ARG SKIP_PHOENIX

# If you are using an umbrella project, you can change this
# argument to the directory the Phoenix app is in so that the assets
# can be built
ARG PHOENIX_SUBDIR=.

ENV SKIP_PHOENIX=${SKIP_PHOENIX} \
  APP_NAME=${APP_NAME} \
  APP_VSN=${APP_VSN} \
  REPLACE_OS_VARS=true \
  TERM=xterm \
  MIX_ENV=prod

# By convention, /opt is typically used for applications
WORKDIR /opt/app

# This step installs all the build tools we'll need
RUN apk update \
  && apk --no-cache --update add nodejs nodejs-npm \
  && mix local.rebar --force \
  && mix local.hex --force

# This copies our app source code into the build container
COPY . .

RUN mix do deps.get, deps.compile, compile

# This step builds assets for the Phoenix app (if there is one)
# If you aren't building a Phoenix app, pass `--build-arg SKIP_PHOENIX=true`
# This is mostly here for demonstration purposes
RUN if [ ! "$SKIP_PHOENIX" = "true" ]; then \
  cd ${PHOENIX_SUBDIR}/assets && \
  npm install && \
  npm run deploy && \
  cd .. && \
  mix phx.digest; \
  fi

RUN \
  mkdir -p /opt/built && \
  mix release --env=prod --verbose && \
  cp _build/${MIX_ENV}/rel/${APP_NAME}/releases/${APP_VSN}/${APP_NAME}.tar.gz /opt/built && \
  cd /opt/built && \
  tar -xzf ${APP_NAME}.tar.gz && \
  rm ${APP_NAME}.tar.gz

# From this line onwards, we're in a new image, which will be the image used in production
FROM alpine:latest

# The name of your application/release (required)
ARG APP_NAME

RUN apk update && apk --no-cache --update add bash openssl-dev

ENV PORT=4000 \
  MIX_ENV=prod \
  REPLACE_OS_VARS=true \
  APP_NAME=${APP_NAME}

WORKDIR /opt/app

EXPOSE ${PORT}

COPY --from=builder /opt/built .

CMD ["/opt/app/bin/${APP_NAME}", "foreground"]