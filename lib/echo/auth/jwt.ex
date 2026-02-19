defmodule Echo.Auth.JWT do
  @moduledoc """
  Módulo para manejar operaciones con JWT.
  """

  alias Joken.Config

  @secret_key Application.compile_env!(:echo, :jwt_secret_key)
  @expiration_hours Application.compile_env(:echo, :jwt_expiration_hours, 24)

  @spec generate_token(integer()) :: {:ok, String.t()} | {:error, atom()}
  def generate_token(user_id) do
    now = DateTime.utc_now()

    claims = %{
      "user_id" => user_id,
      "exp" => DateTime.add(now, @expiration_hours * 3600) |> DateTime.to_unix(),
      "iat" => DateTime.to_unix(now),
      "jti" => generate_jti()
    }

    signer = Joken.Signer.create("HS256", @secret_key)

    case Joken.generate_and_sign(Config.default_claims(), claims, signer) do
      {:ok, token, _claims} -> {:ok, token}
      _ -> {:error, :token_generation_failed}
    end
  end

  @spec verify_token(String.t()) :: {:ok, map()} | {:error, atom()}
  def verify_token(token) do
    signer = Joken.Signer.create("HS256", @secret_key)

    case Joken.verify_and_validate(Config.default_claims(), token, signer) do
      {:ok, claims} ->
        # Verificar expiración manualmente por seguridad
        if is_token_expired?(claims) do
          {:error, :token_expired}
        else
          {:ok, claims}
        end

      {:error, reason} ->
        {:error, reason}
    end
  end

  @spec extract_user_id(String.t()) :: {:ok, integer()} | {:error, atom()}
  def extract_user_id(token) do
    case verify_token(token) do
      {:ok, claims} ->
        case claims["user_id"] do
          nil -> {:error, :invalid_token}
          user_id -> {:ok, user_id}
        end

      {:error, reason} ->
        {:error, reason}
    end
  end

  @spec get_user_id_from_token(String.t()) :: integer() | nil
  def get_user_id_from_token(token) do
    case extract_user_id(token) do
      {:ok, user_id} -> user_id
      _ -> nil
    end
  end

  # Helper functions
  defp generate_jti do
    :crypto.strong_rand_bytes(16)
    |> Base.url_encode64()
    |> String.replace(~r/[\+\/=]/, "")
    |> String.slice(0, 32)
  end

  defp is_token_expired?(claims) do
    case claims["exp"] do
      nil ->
        true

      exp_unix ->
        exp_dt = DateTime.from_unix!(exp_unix)
        DateTime.compare(exp_dt, DateTime.utc_now()) == :lt
    end
  end
end
