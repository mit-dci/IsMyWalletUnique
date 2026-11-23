FROM rust:1-slim-trixie AS build
WORKDIR /app
COPY . .
RUN cargo build --release --locked

# Debian versions must match so the binary finds the same glibc.
FROM gcr.io/distroless/cc-debian13
ARG PORT=8080
ENV PORT=${PORT}
# Static busybox so the compose healthcheck can probe /health.
COPY --from=busybox:1.36.1-musl /bin/busybox /busybox
COPY --from=build /app/target/release/server /server
EXPOSE ${PORT}
CMD ["/server"]
