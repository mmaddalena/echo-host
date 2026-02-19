import Config

if config_env() == :prod do
  database_url =
    System.get_env("DATABASE_URL") ||
      raise """
      environment variable DATABASE_URL is missing.
      For example:
      ecto://postgres:postgres@localhost:5432/echo_prod
      """

  ssl =
  case(System.get_env("DATABASE_SSL")) do
    "true" -> true
    "false" -> false
    nil -> false
  end

  config :echo, Echo.Repo,
    url: database_url,
    pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10"),
    ssl: ssl
end
