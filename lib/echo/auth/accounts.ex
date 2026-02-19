defmodule Echo.Auth.Accounts do
  @moduledoc """
  Módulo para manejar operaciones de cuenta de usuario.
  """

  alias Echo.Auth.Auth
  alias Echo.Users.User

  @doc """
  Inicia sesión de un usuario.

  Returns:
    - {:ok, token} si el login es exitoso
    - {:error, reason} si hay un error
  """
  def login(username, password) do
    with {:ok, user_id} <- Auth.authenticate(username, password),
         {:ok, token} <- Auth.create_token(user_id) do
      {:ok, token}
    else
      {:error, reason} ->
        IO.puts(reason)
        {:error, reason}
    end
  end

  @doc """
  Registra un nuevo usuario.

  Returns:
    - {:ok, token} si el registro (y post login) es exitoso
    - {:error, changeset} si hay errores de validación
    - {:error, :username_taken} si el username ya existe
  """
  def register(params) do
    IO.inspect(User.handle_avatar(params["avatar"]), label: "Handle avatar result")
    with {:ok, avatar_url} <- User.handle_avatar(params["avatar"]),
         clean_params <-
           params
           |> Map.drop(["avatar"])
           |> Map.put("avatar_url", avatar_url),
         {:ok, _user} <- User.create(clean_params),
         {:ok, token} <- login(clean_params["username"], clean_params["password"]) do
      {:ok, token}
    else
      {:error, %Ecto.Changeset{} = cs} ->
        # IO.inspect(cs.errors, label: "REGISTER ERRORS")
        {:error, User.format_changeset_error(cs)}

      {:error, reason} ->
        IO.inspect(reason, label: "REGISTER ERROR")
        {:error, reason}
    end
  end

  # @doc """
  # Cierra sesión de un usuario.
  # """
  # def logout(token) do
  #   # Con JWT stateless, el logout se maneja en el cliente
  #   # eliminando el token. Pero podríamos invalidar el token
  #   # si implementamos una blacklist.
  #   :ok
  # end
end
