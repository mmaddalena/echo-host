import Config

database_url =
  System.get_env("DATABASE_URL") ||
    "ecto://postgres:postgres@localhost:5432/echo_dev"

config :echo, Echo.Repo,
  url: database_url,
  show_sensitive_data_on_connection_error: true,
  pool_size: 10
