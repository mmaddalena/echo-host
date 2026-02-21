defmodule Echo.Chats.ChatSession do
  alias Echo.ProcessRegistry
  # Idem que el UserSession.
  # Es un Genserver que vive mientras la sesion del chat esté viva.
  # La sesión vive despues de x tiempo de inactividad.
  use GenServer
  alias Echo.Chats.Chat
  alias Echo.Repo
  alias Echo.Users.User
  alias Echo.Users.UserSession
  alias Echo.Messages.Messages
  alias Echo.Constants
  alias Echo.ChatMembers.ChatMembers

  def start_link(chat_id) do
    GenServer.start_link(
      __MODULE__,
      chat_id,
      name: {:via, Registry, {Echo.ProcessRegistry, {:chat, chat_id}}}
    )
  end

  ##### Funciones llamadas desde el dominio

  def get_chat_info(cs_pid, user_id, us_pid) do
    GenServer.cast(cs_pid, {:chat_info, user_id, us_pid})
  end

  def send_message(cs_pid, front_msg, us_pid) do
    GenServer.cast(cs_pid, {:send_message, front_msg, us_pid})
  end

  def chat_messages_read(cs_pid, chat_id, user_id) do
    GenServer.cast(cs_pid, {:chat_messages_read, chat_id, user_id})
  end

  def chat_event(cs_pid, payload) do
    GenServer.cast(cs_pid, {:chat_event, payload})
  end

  def change_group_name(cs_pid, chat_id, new_name, changer_user_id) do
    GenServer.cast(cs_pid, {:change_group_name, chat_id, new_name, changer_user_id})
  end

  def change_group_description(cs_pid, chat_id, new_description, changer_user_id) do
    GenServer.cast(cs_pid, {:change_group_description, chat_id, new_description, changer_user_id})
  end

  def give_admin(cs_pid, chat_id, user_id, giving_user_id) do
    GenServer.cast(cs_pid, {:give_admin, chat_id, user_id, giving_user_id})
  end

  def remove_member(cs_pid, chat_id, user_id, member_id) do
    GenServer.cast(cs_pid, {:remove_member, chat_id, user_id, member_id})
  end

  def add_members(cs_pid, chat_id, user_id, member_ids) do
    GenServer.cast(cs_pid, {:add_members, chat_id, user_id, member_ids})
  end

  ##### Callbacks

  @impl true
  def init(chat_id) do
    state = %{
      chat_id: chat_id,
      chat: Chat.get(chat_id),
      last_messages: Chat.get_last_messages(chat_id),
      members: Chat.get_members(chat_id),
    }

    {:ok, state}
  end

  @impl true
  def handle_cast({:chat_info, user_id, us_pid}, state) do
    chat_info = Chat.build_chat_info(state.chat_id, user_id)

    UserSession.send_chat_info(us_pid, chat_info)

    {:noreply, state}
  end


  @impl true
  def handle_cast({:send_message, msg_front, sender_us_pid}, state) do
    front_msg_id = msg_front["front_msg_id"]
    chat_id = msg_front["chat_id"]
    content = msg_front["content"]
    sender_user_id = msg_front["sender_user_id"]
    format = msg_front["format"]
    filename = msg_front["filename"]

    self_chat? =
      state.chat.type == "private" and length(state.members) == 1


    msg_state =
      if state.chat.type == "private" do
        other_user_id =
          state.members
          |> Enum.map(& &1.user_id)
          |> case do
            [only_user] ->
              only_user

            [u1, u2] ->
              if u1 == sender_user_id, do: u2, else: u1

            _ ->
              nil
          end


        case ProcessRegistry.whereis_user_session(other_user_id) do
          nil ->
            Constants.state_sent()

          pid ->
            if UserSession.socket_alive?(pid) do
              Constants.state_delivered()
            else
              Constants.state_sent()
            end
        end
      else
        Constants.state_sent()
      end

    attrs = %{
      chat_id: chat_id,
      content: content,
      user_id: sender_user_id,
      state: msg_state,
      format: format,
      filename: filename
    }

    case Messages.create_message(attrs) do
      {:ok, message} ->
        base_message =
          message
          |> Map.from_struct()
          |> Map.drop([:__meta__, :user, :chat])
          |> Map.put(:time, message.inserted_at)
          |> Map.put(:avatar_url, User.get_avatar_url(sender_user_id))
          |> Map.delete(:inserted_at)

        IO.inspect(base_message, label: "Base message para incoming")
        IO.puts("\n\n\n\n\nSTATE.MEMBERS:")
        IO.inspect(state.members)


        {alive_sessions, _dead_users} =
          Enum.reduce(state.members, {[], []}, fn member, {alive, dead} ->
            user_id = member.user_id

            case ProcessRegistry.whereis_user_session(user_id) do
              nil ->
                {alive, [user_id | dead]}

              us_pid ->
                {[{user_id, us_pid} | alive], dead}
            end
          end)

        cond do
          self_chat? ->
            UserSession.new_message(
              sender_us_pid,
              %{
                type: "new_message",
                message:
                  base_message
                  |> Map.put(:front_msg_id, front_msg_id)
                  |> Map.put(:type, Constants.outgoing())
                  |> Map.put(:sender_name, User.get_name(sender_user_id))
              }
            )
            IO.puts("=|=|=|=|=|=|=|=|=|=|=|=|  MANDAMOS UN SOLO MENSAJE AL USUARIO |=|=|=|=|=|=|=|=|=|=|=|=|=|=|=|=|=|")
          true ->
            Enum.each(alive_sessions, fn {sess_user_id, us_pid} ->
              username = Repo.get(Echo.Schemas.User, sess_user_id).username

              IO.puts(
                "=|=|=|=|=|=|=|=|=|=|=|=|  Usuario VIVO: #{username} |=|=|=|=|=|=|=|=|=|=|=|=|=|=|=|=|=|"
              )

              case sess_user_id == sender_user_id do
                # Es ougoing
                true ->
                  sender_name = User.get_usable_name(sender_user_id, sender_user_id, nil)

                  UserSession.new_message(
                    us_pid,
                    %{
                      type: "new_message",
                      message:
                        base_message
                        |> Map.put(:front_msg_id, front_msg_id)
                        |> Map.put(:type, Constants.outgoing())
                        |> Map.put(:sender_name, sender_name)
                    }
                  )

                # Es incoming
                false ->
                  sender_name = User.get_usable_name(sess_user_id, sender_user_id, nil)

                  UserSession.new_message(
                    us_pid,
                    %{
                      type: "new_message",
                      message:
                        base_message
                        |> Map.put(:front_msg_id, nil)
                        |> Map.put(:type, Constants.incoming())
                        |> Map.put(:sender_name, sender_name)
                    }
                  )
              end
            end)
        end

        {:noreply,
         %{
           state
            | last_messages: [base_message | state.last_messages]
         }}

      {:error, _changeset} ->
        # UserSession.send_message_error(sender_us_pid, front_msg_id, changeset)
        {:noreply, state}
    end
  end

  @impl true
  def handle_cast({:chat_messages_read, chat_id, reader_user_id}, state) do
    Chat.set_messages_read(chat_id, reader_user_id)

    ChatMembers.set_last_read(reader_user_id, chat_id)

    new_last_messages =
      Enum.map(state.last_messages, fn msg ->
        if msg.user_id != reader_user_id and msg.state != Constants.state_read() do
          %{msg | state: Constants.state_read()}
        else
          msg
        end
      end)

    state.members
    |> Enum.map(& &1.user_id)
    |> Enum.reject(&(&1 == reader_user_id))
    |> Enum.each(fn user_id ->
      if us_pid = ProcessRegistry.whereis_user_session(user_id) do
        UserSession.chat_read(us_pid, chat_id, reader_user_id)
      end
    end)

    {:noreply, %{state | last_messages: new_last_messages}}
  end

  @impl true
  def handle_cast({:chat_event, payload}, state) do
    case payload.type do
      "chat_member_removed" ->
        removed_user_id = payload.user_id

        new_members =
          Enum.reject(state.members, fn m ->
            m.user_id == removed_user_id
          end)

        # notify remaining members
        Enum.each(new_members, fn member ->
          if us_pid = ProcessRegistry.whereis_user_session(member.user_id) do
            UserSession.send_payload(us_pid, payload)
          end
        end)

        # notify removed user
        if us_pid = ProcessRegistry.whereis_user_session(removed_user_id) do
          UserSession.send_payload(us_pid, payload)
        end

        {:noreply,
        %{state | members: new_members}}

      "chat_members_added" ->
        new_members = Chat.get_members(state.chat_id)
        added_user_ids = payload.added_user_ids

        Enum.each(new_members, fn member ->
          if us_pid = ProcessRegistry.whereis_user_session(member.user_id) do
            if member.user_id in added_user_ids do
              # Newly added user → must receive chat_item
              chat_item = Chat.build_chat_info(state.chat_id, member.user_id)

              UserSession.send_payload(us_pid, %{
                type: "chat_added",
                chat_item: chat_item
              })
            else
              # Existing member → only update members
              UserSession.send_payload(us_pid, %{
                type: "chat_members_added",
                chat_id: state.chat_id,
                members: new_members
              })
            end
          end
        end)

        {:noreply, %{state | members: new_members}}

      "chat_admin_changed" ->
        new_admin_id = payload.new_admin_id

        new_members =
          Enum.map(state.members, fn m ->
            if m.user_id == new_admin_id do
              %{m | role: "admin"}
            else
              m
            end
          end)

        # Notify all members about the new admin
        Enum.each(new_members, fn member ->
          if us_pid = ProcessRegistry.whereis_user_session(member.user_id) do
            UserSession.send_payload(us_pid, payload)
          end
        end)

        {:noreply, %{state | members: new_members}}
  end
end

  def handle_cast({:change_group_name, chat_id, new_name, changer_user_id}, state) do
    payload = case Chat.change_group_name(chat_id, new_name, changer_user_id) do
      {:ok, _result} ->
        %{
          type: "group_name_change_result",
          status: "success",
          chat_id: chat_id,
          new_name: new_name,
          changer_user_id: changer_user_id
        }

      {:error, reason} ->
        %{
          type: "group_name_change_result",
          status: "failure",
          chat_id: chat_id,
          reason: reason
        }
    end

    if (payload.status == "success") do
      # Notificamos a los miembros del cambio
      Enum.each(state.members, fn member ->
        if us_pid = ProcessRegistry.whereis_user_session(member.user_id) do
          UserSession.send_payload(us_pid, payload)
        end
      end)
      {:noreply, %{state | chat: %{state.chat | name: new_name}}}
    else
      # Notificamos sólo al que quiso hacer el cambio
      if us_pid = ProcessRegistry.whereis_user_session(changer_user_id) do
        UserSession.send_payload(us_pid, payload)
      end
      {:noreply, state}
    end
  end

  def handle_cast({:change_group_description, chat_id, new_description, changer_user_id}, state) do
    payload = case Chat.change_group_description(chat_id, new_description, changer_user_id) do
      {:ok, _result} ->
        %{
          type: "group_description_change_result",
          status: "success",
          chat_id: chat_id,
          new_description: new_description,
          changer_user_id: changer_user_id
        }

      {:error, reason} ->
        %{
          type: "group_description_change_result",
          status: "failure",
          chat_id: chat_id,
          changer_user_id: changer_user_id,
          reason: reason
        }
    end

    if (payload.status == "success") do
      # Notificamos a los miembros del cambio
      Enum.each(state.members, fn member ->
        if us_pid = ProcessRegistry.whereis_user_session(member.user_id) do
          UserSession.send_payload(us_pid, payload)
        end
      end)
      {:noreply, %{state | chat: %{state.chat | description: new_description}}}
    else
      # Notificamos sólo al que quiso hacer el cambio
      if us_pid = ProcessRegistry.whereis_user_session(changer_user_id) do
        UserSession.send_payload(us_pid, payload)
      end
      {:noreply, state}
    end
  end

  def handle_cast({:give_admin, chat_id, user_id, giving_user_id}, state) do
    case Chat.give_admin(chat_id, user_id, giving_user_id) do
      {:ok, updated_member} ->
        new_members =
          Enum.map(state.members, fn m ->
            if m.user_id == updated_member.user_id do
              updated_member
            else
              m
            end
          end)

        Enum.each(new_members, fn member ->
          enriched =
            enrich_member(updated_member, member.user_id)

          if us_pid = ProcessRegistry.whereis_user_session(member.user_id) do
            UserSession.send_payload(us_pid, %{
              type: "admin_given_to_member",
              chat_id: chat_id,
              member: enriched,
              giving_user_id: giving_user_id
            })
          end
        end)


        {:noreply, %{state | members: new_members}}

      {:error, _reason} ->
        {:noreply, state}
    end
  end

  def handle_cast({:remove_member, chat_id, user_id, member_id}, state) do
    Chat.remove_member(chat_id, user_id, member_id)
    new_members = Enum.reject(state.members, fn m -> m.user_id == member_id end)
    {:noreply, %{state | members: new_members}}
  end

  def handle_cast({:add_members, chat_id, user_id, member_ids}, state) do
    Chat.add_members(chat_id, user_id, member_ids)
    new_members = Chat.get_members(chat_id)
    {:noreply, %{state | members: new_members}}
  end


  def enrich_member(member, viewer_id) do
    Map.put(member, :nickname, User.get_nickname(viewer_id, member.user_id))
  end








  @doc """
  Broadcast a message to all processes subscribed to a chat
  """
  def broadcast(chat_id, payload) do
    Registry.dispatch(ProcessRegistry, {:chat, chat_id}, fn entries ->
      for {pid, _meta} <- entries do
        chat_event(pid, payload)
      end
    end)
  end
end
