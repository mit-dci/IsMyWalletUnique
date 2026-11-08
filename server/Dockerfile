FROM rust:1-slim-trixie AS build
WORKDIR /app
COPY . .
RUN cargo build --release --locked

# Debian versions must match so the binary finds the same glibc.
FROM gcr.io/distroless/cc-debian13
COPY --from=build /app/target/release/server /server
EXPOSE 3000
CMD ["/server"]
