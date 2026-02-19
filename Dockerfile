FROM elixir:1.18-alpine

# Dependencias del sistema para compilar NIFs
RUN apk add --no-cache build-base git nodejs npm

WORKDIR /app

ENV GOOGLE_APPLICATION_CREDENTIALS=/app/priv/gcp/service-account.json

# Copiamos mix files primero (cache)
COPY mix.exs mix.lock ./
RUN mix local.hex --force && mix local.rebar --force
RUN mix deps.get
RUN mix deps.compile

# Copiamos el resto del proyecto
COPY . .

# Compilamos la app
RUN mix compile

CMD ["mix", "run", "--no-halt"]