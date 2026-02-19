import Config

database_url =
  System.get_env("DATABASE_URL") ||
    "ecto://postgres:postgres@localhost:5432/echo_test"

config :echo, Echo.Repo,
  url: database_url,
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 10,
  log: false

#config :bcrypt_elixir, :log_rounds, 4

# Safer test JWT
config :echo,
  jwt_secret_key: "test_secret_key",
  jwt_expiration_hours: 1
