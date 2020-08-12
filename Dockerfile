## SYSTEM

FROM hexpm/elixir:1.10.3-erlang-23.0.3-ubuntu-focal-20200703 AS builder
WORKDIR /app

ENV LANG=C.UTF-8 \
    LANGUAGE=C:en \
    LC_ALL=C.UTF-8 \
    DEBIAN_FRONTEND=noninteractive \
    TERM=xterm \
    MIX_ENV=prod

RUN mix local.rebar --force && \
    mix local.hex --if-missing --force

COPY mix.* ./
COPY config ./config
COPY VERSION .
RUN mix do deps.get, deps.compile

## FRONTEND

FROM node:12.18.3-alpine AS frontend
WORKDIR /app
# PurgeCSS needs to see the Elixir stuff
COPY lib ./lib
COPY assets/package.json assets/yarn.lock ./assets/
COPY --from=builder /app/deps/phoenix ./deps/phoenix
COPY --from=builder /app/deps/phoenix_html ./deps/phoenix_html
COPY --from=builder /app/deps/phoenix_live_view ./deps/phoenix_live_view
RUN yarn --cwd ./assets install --no-progress --frozen-lockfile

COPY assets ./assets
RUN yarn --cwd ./assets run deploy

## APP

FROM builder AS app
COPY --from=frontend /app/priv/static ./priv/static
COPY lib ./lib
COPY posts ./posts
RUN mix phx.digest

CMD ["/bin/bash"]