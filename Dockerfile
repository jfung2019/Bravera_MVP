# syntax = docker/dockerfile:experimental
FROM plangora/alpine-elixir-phoenix:otp-23.3.2-elixir-1.11.3 as phx-builder

ENV PORT=5000 MIX_ENV=prod

ADD . .

# Run frontend build, compile, and digest assets, and set default to own the directory
RUN --mount=type=secret,id=auto-devops-build-secrets . /run/secrets/auto-devops-build-secrets && \
    mix deps.get && cd assets/ && \
		npm install && \
    npm run deploy && \
    cd - && \
    mix do compile, phx.digest, release

FROM plangora/alpine-erlang:23.3.2

EXPOSE 5000
ENV PORT=5000 MIX_ENV=prod

COPY --from=phx-builder /opt/app/_build/prod/rel/omega_bravera/ /opt/app/
RUN chown -R default /opt/app/
RUN apk --update add imagemagick file

USER default

CMD ["/opt/app/bin/omega_bravera", "foreground"]