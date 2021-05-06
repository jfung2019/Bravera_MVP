FROM plangora/alpine-elixir-phoenix:otp-23.3.2-elixir-1.11.3 as phx-builder

ENV PORT=4000 MIX_ENV=prod

ADD . .

# Run frontend build, compile, and digest assets, and set default to own the directory
RUN mix deps.get && cd assets/ && \
		npm install && \
    npm run deploy && \
    cd - && \
    mix do compile, phx.digest, release --env docker

FROM plangora/alpine-erlang:23.3.2

EXPOSE 4000
ENV PORT=4000 MIX_ENV=prod

COPY --from=phx-builder /opt/app/_build/prod/rel/omega_bravera/ /opt/app/
RUN chown -R default /opt/app/
RUN apk --update add imagemagick file

USER default

CMD ["/opt/app/bin/omega_bravera", "foreground"]