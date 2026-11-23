FROM caddy:2.11.9-builder AS build
RUN xcaddy build --with github.com/mholt/caddy-ratelimit@v0.1.1-0.20260612195517-5625512f24f6

FROM caddy:2.11.9
COPY --from=build /usr/bin/caddy /usr/bin/caddy
