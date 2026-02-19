defmodule Echo.WS.UserSocket do
  @behaviour :cowboy_websocket

  require Logger
  alias Echo.Users.UserSession

  # Handshake inicial. Decide si este proceso en HTTP se convierte a WS
  @impl true
  def init(req, _opts) do
    case extract_token(req) do
      {:ok, token} ->
        case Echo.Auth.Auth.verify_token(token) do
          {:ok, user_id} ->
            state = %{
              user_id: user_id,
              user_session: nil,
              token: token,
              authenticated: true
            }

            {:cowboy_websocket, req, state, %{idle_timeout: 300_000}}

          {:error, :token_expired} ->
            Logger.warning("Token expired for WebSocket connection", nil)
            {:reply, {:close, 1008, "Token expired"}, req, %{}}

          {:error, _reason} ->
            Logger.warning("Invalid token for WebSocket connection", nil)
            {:reply, {:close, 1008, "Unauthorized"}, req, %{}}
        end

      :error ->
        Logger.warning("Missing token for WebSocket connection", nil)
        {:reply, {:close, 1008, "Token missing"}, req, %{}}
    end
  end

  # Cowboy llama a este init porque el otro init autorizó el upgrade
  # El proceso YA es un WS (sería equivalente a GenServer.init)
  @impl true
  def websocket_init(state) do
    {:ok, us_pid} = Echo.Users.UserSessionSup.get_or_start(state.user_id)

    UserSession.login(us_pid, self())

    {:ok, %{state | user_session: us_pid}}
  end




  # Mensajes que llegan DESDE el cliente
  @impl true
  def websocket_handle({:text, raw}, state) do
    case Jason.decode(raw) do
      {:ok, msg} ->
        dispatch(msg, state)

      _ ->
        {:ok, state}
    end
  end


  # Dispatch de mensajes del cliente
  defp dispatch(%{"type" => "open_chat", "chat_id" => chat_id}, state) do
    UserSession.open_chat(state.user_session, chat_id)
    {:ok, state}
  end

  defp dispatch(%{"type" => "send_message", "msg" => front_msg}, state) do
    UserSession.send_message(state.user_session, front_msg)
    {:ok, state}
  end

  defp dispatch(%{"type" => "chat_messages_read", "chat_id" => chat_id}, state) do
    UserSession.chat_messages_read(state.user_session, chat_id)
    {:ok, state}
  end

  defp dispatch(%{"type" => "get_contacts"}, state) do
    UserSession.get_contacts(state.user_session)
    {:ok, state}
  end

  defp dispatch(%{"type" => "get_person_info", "person_id" => person_id}, state) do
    UserSession.get_person_info(state.user_session, person_id)
    {:ok, state}
  end

  defp dispatch(%{"type" => "search_people", "input" => input}, state) do
    UserSession.search_people(state.user_session, input)
    {:ok, state}
  end

  defp dispatch(%{"type" => "create_private_chat", "user_id" => receiver_id}, state) do
    UserSession.create_private_chat(state.user_session, receiver_id)
    {:ok, state}
  end

  defp dispatch(%{"type" => "change_username", "new_username" => new_username}, state) do
    UserSession.change_username(state.user_session, new_username)
    {:ok, state}
  end

  defp dispatch(%{"type" => "change_name", "new_name" => new_name}, state) do
    UserSession.change_name(state.user_session, new_name)
    {:ok, state}
  end

  defp dispatch(%{"type" => "change_nickname", "user_id" => contact_id, "new_nickname" => new_nickname}, state) do
    UserSession.change_nickname(state.user_session, contact_id, new_nickname)
    {:ok, state}
  end

  defp dispatch(%{"type" => "add_contact", "user_id" => user_id}, state) do
    UserSession.add_contact(state.user_session, user_id)
    {:ok, state}
  end

  defp dispatch(%{"type" => "delete_contact", "user_id" => user_id}, state) do
    UserSession.delete_contact(state.user_session, user_id)
    {:ok, state}
  end

  defp dispatch(
    %{
      "type" => "create_group",
      "name" => name,
      "description" => description,
      "avatar_url" => avatar_url,
      "member_ids" => member_ids
    },
    state
  ) do
    UserSession.create_group(
      state.user_session,
      %{
        name: name,
        description: description,
        avatar_url: avatar_url,
        member_ids: member_ids
      }
    )

    {:ok, state}
  end

  defp dispatch(%{"type" => "change_group_name", "chat_id" => chat_id, "new_name" => new_name}, state) do
    UserSession.change_group_name(state.user_session, chat_id, new_name)
    {:ok, state}
  end

  defp dispatch(%{"type" => "change_group_description", "chat_id" => chat_id, "new_description" => new_description}, state) do
    UserSession.change_group_description(state.user_session, chat_id, new_description)
    {:ok, state}
  end

  defp dispatch(%{"type" => "give_admin", "chat_id" => chat_id, "user_id" => user_id}, state) do
    UserSession.give_admin(state.user_session, chat_id, user_id)
    {:ok, state}
  end

  defp dispatch(%{"type" => "remove_member", "chat_id" => chat_id, "member_id" => member_id}, state) do
    UserSession.remove_member(state.user_session, chat_id, member_id)
    {:ok, state}
  end

  defp dispatch(%{"type" => "add_members", "chat_id" => chat_id, "member_ids" => member_ids}, state) do
    UserSession.add_members(state.user_session, chat_id, member_ids)
    {:ok, state}
  end

  defp dispatch(%{"type" => "logout"}, state) do
    UserSession.logout(state.user_session)
    #Process.exit(state.user_session, :normal)
    {:ok, state}
  end

  defp dispatch(_unknown, state) do
    {:ok, state}
  end



  # Mensajes que llegan DESDE el backend (OTP)
  # El :reply hace que Cowboy le mande el segundo arg al Cliente
  @impl true
  def websocket_info({:send, payload}, state) do
    {:reply, {:text, Jason.encode!(payload)}, state}
  end

  @impl true
  def websocket_info(_msg, state) do
    {:ok, state}
  end


  # Helper
  defp extract_token(req) do
    # 1. Intentar obtener de query params
    qs = :cowboy_req.parse_qs(req)

    case List.keyfind(qs, "token", 0) do
      {_, token} ->
        {:ok, token}

      nil ->
        # 2. Intentar obtener de headers Authorization: Bearer
        headers = :cowboy_req.headers(req)

        case :proplists.get_value("authorization", headers) do
          "Bearer " <> token ->
            {:ok, String.trim(token)}

          _ ->
            # 3. Intentar obtener de cookies
            cookies = :cowboy_req.parse_cookies(req)

            case List.keyfind(cookies, "token", 0) do
              {_, token} -> {:ok, token}
              nil -> :error
            end
        end
    end
  end

end
