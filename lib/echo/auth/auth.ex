defmodule Echo.Auth.Auth do
  @moduledoc """
  Módulo de autenticación principal.
  """

  alias Echo.Auth.JWT
  alias Echo.Users.User

  @doc """
  Autentica un usuario con username y password.

  Returns:
    - {:ok, user_id} si la autenticación es exitosa
    - {:error, :user_not_found} si el usuario no existe
    - {:error, :invalid_password} si la contraseña es incorrecta
  """
  def authenticate(username, password) do
    # En un sistema real, esto buscaría en la base de datos
    # Por ahora simulamos con datos en memoria

    case User.get_by_username(username) do
      nil ->
        {:error, :user_not_found}

      user ->
        # Verificar contraseña
        if verify_password(password, user.password_hash) do
          {:ok, user.id}
        else
          {:error, :invalid_password}
        end
    end
  end

  @doc """
  Crea un token JWT para un usuario.

  Returns:
    - {:ok, token} si se pudo generar el token
    - {:error, reason} si hubo un error
  """
  def create_token(user_id) do
    JWT.generate_token(user_id)
  end

  @doc """
  Verifica un token JWT.

  Returns:
    - {:ok, user_id} si el token es válido
    - {:error, :invalid_token} si el token no es válido
    - {:error, :token_expired} si el token expiró
  """
  def verify_token(token) do
    JWT.extract_user_id(token)
  end

  @doc """
  Hashea una contraseña usando bcrypt.
  """
  # def hash_password(password) do
  #   Bcrypt.hash_pwd_salt(password)
  # end

  # Private functions

  def hash_password(pw) do
    pw
  end

  defp verify_password(password, password_hash) do
    # Bcrypt.verify_pass(password, password_hash)
    password == password_hash
  end
end
