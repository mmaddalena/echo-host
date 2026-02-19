import Config

# Repo registration
config :echo,
  ecto_repos: [Echo.Repo]

# JWT (shared defaults)
config :joken,
  default_signer: "dev_secret_change_this_in_production_min_32_chars_long_please"

config :echo,
  jwt_secret_key:
    System.get_env("JWT_SECRET_KEY") ||
      "default_dev_secret_change_in_production_min_32_chars",
  jwt_expiration_hours: 24

import_config "#{config_env()}.exs"
