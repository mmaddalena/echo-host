defmodule Echo.Users.UserSession do
  @moduledoc """
  Es un genserver que maneja toda la sesion del usuario.
  Se crea cuando el usuario se logea, y vive hasta que se logoutea o
  hasta que pase x tiempo de inactividad.


  En su estado guarda cosas de rápido y frecuente acceso como:
  id del usuario,
  últimos n mensajes,
  last activity,
  last_chat_opened_id
  texto escrito pero no mandado (en borrador)
    (este no deberia estar aca, porque un usuario podria tener un borrador en mas de un chat igual)
  """

  use GenServer
  alias Echo.ProcessRegistry
  alias Echo.Users.User
  alias Echo.Messages.Messages
  alias Echo.Contacts.Contacts
  alias Echo.Chats.ChatSession
  alias Echo.Chats.ChatSessionSup
  alias Echo.Chats.Chat
  alias Echo.Constants
  alias Echo.ChatMembers.ChatMembers

  def start_link(user_id) do
    GenServer.start_link(
      __MODULE__,
      user_id,
      name: {:via, Registry, {ProcessRegistry, {:user, user_id}}}
    )
  end

  ##### Funciones llamadas desde el socket

  def login(us_pid, socket_pid) do
    GenServer.cast(us_pid, {:login, socket_pid})
  end

  def open_chat(us_pid, chat_id) do
    GenServer.cast(us_pid, {:open_chat, chat_id})
  end

  def send_message(us_pid, front_msg) do
    GenServer.cast(us_pid, {:send_message, front_msg})
  end

  def chat_messages_read(us_pid, chat_id) do
    GenServer.cast(us_pid, {:chat_messages_read, chat_id})
  end

  def get_contacts(us_pid) do
    GenServer.cast(us_pid, :get_contacts)
  end

  def get_person_info(us_pid, person_id) do
    GenServer.cast(us_pid, {:get_person_info, person_id})
  end

  def search_people(us_pid, input) do
    GenServer.cast(us_pid, {:search_people, input})
  end

  def create_private_chat(us_pid, receiver_id) do
    GenServer.cast(us_pid, {:create_private_chat, receiver_id})
  end

  def change_username(us_pid, new_username) do
    GenServer.cast(us_pid, {:change_username, new_username})
  end

  def change_name(us_pid, new_name) do
    GenServer.cast(us_pid, {:change_name, new_name})
  end

  def change_nickname(us_pid, contact_id, new_nickname) do
    GenServer.cast(us_pid, {:change_nickname, contact_id, new_nickname})
  end

  def create_group(us_pid, group_payload) do
    GenServer.cast(us_pid, {:create_group, group_payload})
  end

  def add_contact(us_pid, user_id) do
    GenServer.cast(us_pid, {:add_contact, user_id})
  end

  def delete_contact(us_pid, user_id) do
    GenServer.cast(us_pid, {:delete_contact, user_id})
  end

  def change_group_name(us_pid, chat_id, new_name) do
    GenServer.cast(us_pid, {:change_group_name, chat_id, new_name})
  end

  def change_group_description(us_pid, chat_id, new_description) do
    GenServer.cast(us_pid, {:change_group_description, chat_id, new_description})
  end

  def give_admin(us_pid, chat_id, user_id) do
    GenServer.cast(us_pid, {:give_admin, chat_id, user_id})
  end

  def remove_member(us_pid, chat_id, member_id) do
    GenServer.cast(us_pid, {:remove_member, chat_id, member_id})
  end

  def add_members(us_pid, chat_id, member_ids) do
    GenServer.cast(us_pid, {:add_members, chat_id, member_ids})
  end

  def logout(us_pid) do
    GenServer.call(us_pid, :logout)
  end

  ##### Funciones llamadas desde el dominio

  def send_chat_info(us_pid, chat_info) do
    GenServer.cast(us_pid, {:send_chat_info, chat_info})
  end

  def new_message(us_pid, msg) do
    GenServer.cast(us_pid, {:new_message, msg})
  end

  def chat_read(us_pid, chat_id, reader_user_id) do
    GenServer.cast(us_pid, {:chat_read, chat_id, reader_user_id})
  end

  def socket_alive?(pid) do
    GenServer.call(pid, :socket_alive?)
  end

  def messages_delivered(us_pid, message_ids) do
    GenServer.cast(us_pid, {:messages_delivered, message_ids})
  end

  # Manda el payload tal cual al socket, se usa acá mismo por otro UserSession
  def send_payload(us_pid, payload) do
    GenServer.cast(us_pid, {:send_payload, payload})
  end

  ##### Callbacks

  @impl true
  def init(user_id) do
    Process.flag(:trap_exit, true)

    user = User.get(user_id)

    state = %{
      user_id: user_id,
      user: user,
      socket: nil,
      current_chat_id: nil,
      disconnect_timer: nil
    }

    {:ok, state}
  end

  @impl true
  def handle_cast({:login, socket_pid}, state) do
    new_state =
    state
    |> attach_socket(socket_pid)
    |> send_user_info()
    |> mark_pending_messages_delivered()

    # Broadcast that user is now online
    broadcast_user_status(state.user_id, true)

    {:noreply, new_state}
  end


  @impl true
  def handle_cast({:open_chat, chat_id}, state) do
    case ChatMembers.member?(chat_id, state.user_id) do
      true ->
        {:ok, cs_pid} = ChatSessionSup.get_or_start(chat_id)
        ChatSession.get_chat_info(cs_pid, state.user_id, self())

        {:noreply, state}

      false ->
        # User is no longer member → reject
        send(state.socket, {:send,
          %{
            type: "chat_forbidden",
            chat_id: chat_id
          }
        })

        IO.puts("\nUser tried to open forbidden chat #{chat_id}\n")

        {:noreply, state}
    end
  end


  @impl true
  def handle_cast({:send_chat_info, chat_info}, state) do
    msg = %{
      type: "chat_info",
      chat: chat_info
    }

    send(state.socket, {:send, msg})

    {:noreply, state}
  end


  @impl true
  def handle_cast({:send_message, front_msg}, state) do
    {:ok, cs_pid} = ChatSessionSup.get_or_start(front_msg["chat_id"])

    ChatSession.send_message(cs_pid, front_msg, self())

    {:noreply, state}
  end

  @impl true
  def handle_cast({:new_message, _msg}, %{socket: nil} = state) do
    {:noreply, state}
  end
  @impl true
  def handle_cast({:new_message, msg}, state) do
    if (state.socket != nil) do
      send(state.socket, {:send, msg})
    end

    {:noreply, state}
  end

  @impl true
  def handle_cast({:chat_messages_read, chat_id}, state) do
    {:ok, cs_pid} = ChatSessionSup.get_or_start(chat_id)

    ChatSession.chat_messages_read(cs_pid, chat_id, state.user_id)

    {:noreply, state}
  end

  @impl true
  def handle_cast({:chat_read, chat_id, reader_user_id}, state) do
    msg = %{
      type: "chat_read",
      chat_id: chat_id,
      reader_user_id: reader_user_id
    }
    if state.socket, do: send(state.socket, {:send, msg})
    {:noreply, state}
  end

  @impl true
  def handle_cast({:messages_delivered, _message_ids}, %{socket: nil} = state) do
    {:noreply, state}
  end
  @impl true
  def handle_cast({:messages_delivered, message_ids}, state) do
    send(state.socket, {:send, %{type: "messages_delivered", message_ids: message_ids}})
    {:noreply, state}
  end

  @impl true
  def handle_cast(:mark_pending_delivered, state) do
    # traemos todos los mensajes donde user_id != state.user_id y state == sent
    messages = Messages.get_sent_messages_for_user(state.user_id)
    IO.puts("Mensajes: #{inspect(messages)}")

    Enum.each(messages, fn msg ->
      if us_pid = ProcessRegistry.whereis_user_session(msg.user_id) do
        messages_delivered(us_pid, [msg.id])
      end
    end)

    {:noreply, state}
  end

  @impl true
  def handle_cast(:get_contacts, state) do
    IO.puts("\n\nSE PIDIERON LOS CONTACTOS DEL USUARIO #{state.user.username}\n")

    contacts = Contacts.list_contacts_for_user(state.user_id)
    front_contacts = serialize_contacts_for_front(contacts)

    send(state.socket, {:send, %{type: "contacts", contacts: front_contacts}})

    IO.puts("SE ENVIAN LOS CONTACTOS: #{inspect(front_contacts)}")

    {:noreply, state}

  end

  @impl true
  def handle_cast({:get_person_info, person_id}, state) do
    IO.puts("\n\n SE PIDIÓ LA INFO DEL USUARIO #{inspect(person_id)}\n")
    info = User.get_person_info(person_id, state.user_id)
    send(state.socket, {:send,
      %{
        type: "person_info",
        person_info: info
      }
    })
    {:noreply, state}
  end

  @impl true
  def handle_cast({:search_people, input}, state) do
    IO.puts("\n\n SE HIZO UNA BÚSQUEDA DE USUARIOS CON ESTE INPUT: #{input}\n")
    users = User.search_users(state.user_id, input)
    front_users = serialize_users_for_search(users, state.user_id)
    send(state.socket, {:send,
      %{
        type: "search_people_results",
        search_people_results: front_users
      }
    })
    {:noreply, state}
  end


  @impl true
  def handle_cast({:create_private_chat, receiver_id}, state) do
    IO.puts("\n\n SE QUIERE CREAR UN CHAT PRIVADO ENTRE #{state.user_id} Y #{receiver_id}\n")
    chat_id = Chat.create_private_chat(state.user_id, receiver_id)

    IO.puts("\n\n EL CHATID CREADO ES: #{chat_id}\n")

    chat_info_a = Chat.build_chat_info(chat_id, state.user_id)
    chat_item_a = Chat.build_chat_list_item(chat_id, state.user_id)

    send(state.socket, {:send,
      %{
        type: "private_chat_created",
        chat: chat_info_a,
        chat_item: chat_item_a
      }
    })

    IO.puts("\n\n SE ENVIÓ EL MENSAJE DE QUE SE CREÓ EL CHAT AL EMISOR\n")
    if (state.user_id != receiver_id) do
      if other_us_pid = ProcessRegistry.whereis_user_session(receiver_id) do
        chat_item_b = Chat.build_chat_list_item(chat_id, receiver_id)

        send_payload(other_us_pid, %{
          type: "private_chat_created",
          chat_item: chat_item_b
        })
      end
    end

    {:noreply, state}
  end

  @impl true
  def handle_cast({:change_username, new_username}, state) do
    IO.puts("\n\n\n SE QUIERE CAMBIAR EL USERNAME A #{new_username}\n\n\n")

    {status, extra} =
      case User.change_username(state.user_id, new_username) do
        :ok ->
          {:success, %{new_username: new_username}}

        {:error, reason} ->
          {:failure, %{reason: reason}}
      end

    payload = %{
      type: "username_change_result",
      status: status,
      data: extra
    }

    send(state.socket, {:send, payload})
    {:noreply, %{state | user: User.get(state.user_id)}}
  end

  @impl true
  def handle_cast({:change_name, new_name}, state) do
    IO.puts("\n\n\n SE QUIERE CAMBIAR EL NAME A #{new_name}\n\n\n")

    {status, extra} =
      case User.change_name(state.user_id, new_name) do
        {:ok, _user} ->
          {:success, %{new_name: new_name}}

        {:error, changeset} ->
          {:failure, %{reason: changeset}}
      end

    payload = %{
      type: "name_change_result",
      status: status,
      data: extra
    }

    send(state.socket, {:send, payload})
    {:noreply, %{state | user: User.get(state.user_id)}}
  end

  @impl true
  def handle_cast({:change_nickname, contact_id, new_nickname}, state) do
    IO.puts("\n\n\n SE QUIERE CAMBIAR EL NICKNAME A #{new_nickname}\n\n\n")

    {status, extra} =
      case User.change_nickname(state.user_id, contact_id, new_nickname) do
        :ok ->
          {:success, %{contact_id: contact_id, new_nickname: new_nickname}}

        {:error, changeset} ->
          {:failure, %{reason: changeset}}
      end

    payload = %{
      type: "nickname_change_result",
      status: status,
      data: extra
    }

    send(state.socket, {:send, payload})
    {:noreply, %{state | user: User.get(state.user_id)}}
  end

  @impl true
  def handle_cast(
        {:create_group,
        %{
          name: name,
          description: description,
          avatar_url: avatar_url,
          member_ids: member_ids
        }},
        state
      )
  do
    creator_id = state.user_id

    members =
      member_ids
      |> Enum.uniq()
      |> Enum.concat([creator_id])
      |> Enum.uniq()

    {:ok, chat_id} =
      Chat.create_group_chat(
        %{
          name: name,
          description: description,
          avatar_url: avatar_url,
          creator_id: creator_id,
          member_ids: members
        }
      )

    # Payload for creator (full chat info)
    chat_info = Chat.build_chat_info(chat_id, creator_id)
    chat_item = Chat.build_chat_list_item(chat_id, creator_id)

    send(state.socket, {:send,
      %{
        type: "group_chat_created",
        chat: chat_info,
        chat_item: chat_item
      }
    })

    # Notify other members
    Enum.each(members, fn member_id ->
      if member_id != creator_id do
        if us_pid = ProcessRegistry.whereis_user_session(member_id) do
          chat_item_other = Chat.build_chat_list_item(chat_id, member_id)

          send_payload(us_pid, %{
            type: "group_chat_created",
            chat_item: chat_item_other
          })
        end
      end
    end)

    {:noreply, state}
  end


  @impl true
  def handle_cast({:add_contact, user_id}, state) do
    case Contacts.add_contact(state.user_id, user_id) do
      {:ok, contact_info} ->
        send(state.socket, {:send,
          %{
            type: "contact_addition",
            status: "success",
            data: %{
              contact: serialize_contact_for_front(contact_info)
            }
          }}
        )
      {:error, changeset} ->
        send(state.socket, {:send,
          %{
            type: "contact_addition",
            status: "failure",
            data: %{
              reason: changeset
            }
          }}
        )
    end
    {:noreply, state}
  end

  @impl true
  def handle_cast({:delete_contact, user_id}, state) do
    case Contacts.delete_contact(state.user_id, user_id) do
      :ok ->
        send(state.socket, {:send,
          %{
            type: "contact_deletion",
            status: "success",
            data: %{
              user_id: user_id
            }
          }}
        )
      {:error, changeset} ->
        send(state.socket, {:send,
          %{
            type: "contact_deletion",
            status: "failure",
            data: %{
              reason: changeset
            }
          }}
        )
    end
    {:noreply, state}
  end


  def handle_cast({:change_group_name, chat_id, new_name}, state) do
    IO.puts("\n\n\n SE QUIERE CAMBIAR EL GROUP NAME A #{new_name}\n\n\n")

    {:ok, cs_pid} = ChatSessionSup.get_or_start(chat_id)

    ChatSession.change_group_name(cs_pid, chat_id, new_name, state.user_id)

    {:noreply, state}
  end

  def handle_cast({:change_group_description, chat_id, new_description}, state) do
    IO.puts("\n\n\n SE QUIERE CAMBIAR EL GROUP DESCRIPTION A #{new_description}\n\n\n")

    {:ok, cs_pid} = ChatSessionSup.get_or_start(chat_id)

    ChatSession.change_group_description(cs_pid, chat_id, new_description, state.user_id)

    {:noreply, state}
  end

  def handle_cast({:give_admin, chat_id, user_id}, state) do
    IO.puts("\n\n\n SE LE QUIERE DAR ADMIN A #{user_id}\n\n\n")

    {:ok, cs_pid} = ChatSessionSup.get_or_start(chat_id)

    ChatSession.give_admin(cs_pid, chat_id, user_id, state.user_id)

    {:noreply, state}
  end

  def handle_cast({:remove_member, chat_id, member_id}, state) do

    {:ok, cs_pid} = ChatSessionSup.get_or_start(chat_id)

    ChatSession.remove_member(cs_pid, chat_id, state.user_id, member_id)

    {:noreply, state}
  end

  def handle_cast({:add_members, chat_id, member_ids}, state) do

    {:ok, cs_pid} = ChatSessionSup.get_or_start(chat_id)

    ChatSession.add_members(cs_pid, chat_id, state.user_id, member_ids)

    {:noreply, state}
  end

  @impl true
  def handle_cast({:send_payload, _payload}, %{socket: nil} = state) do
    # Socket is not alive, just ignore
    {:noreply, state}
  end

  def handle_cast({:send_payload, payload}, state) do
    send(state.socket, {:send, payload})
    {:noreply, state}
  end

  ################### Helpers
  defp attach_socket(state, socket_pid) do
    Process.link(socket_pid)

    if state.disconnect_timer do
      Process.cancel_timer(state.disconnect_timer)
    end

    %{state |
        socket: socket_pid,
        disconnect_timer: nil,
        #user: user = User.get(user_id)
    }
  end
  defp send_user_info(state) do
    user_info = %{
      type: "user_info",
      user: User.user_payload(state.user),
      last_chats: User.last_chats(state.user_id)
    }

    send(state.socket, {:send, user_info})

    state
  end
  defp mark_pending_messages_delivered(state) do
    messages = Messages.get_sent_messages_for_user(state.user_id)

    Messages.mark_delivered_for_user(state.user_id)

    messages
    |> Enum.group_by(& &1.user_id) # sender_id
    |> Enum.each(fn {sender_id, msgs} ->
      if us_pid = ProcessRegistry.whereis_user_session(sender_id) do
        messages_delivered(us_pid, Enum.map(msgs, & &1.id))
      end
    end)

    state
  end


  defp serialize_contacts_for_front(contacts) do
    Enum.map(contacts, fn c ->
      serialize_contact_for_front(c)
    end)
  end

  defp serialize_contact_for_front(c) do
    %{
      id: c.contact.id,
      username: c.contact.username,
      name: c.contact.name,
      avatar_url: c.contact.avatar_url,
      last_seen_at: c.contact.last_seen_at,
      contact_info: %{
        owner_user_id: c.user_id,
        nickname: c.nickname,
        added_at: c.inserted_at
      }
    }
  end

  defp serialize_users_for_search(users, asking_user_id) do
    contacts_map = Contacts.get_contacts_map(asking_user_id)

    Enum.map(users, fn user ->
      base = %{
        id: user.id,
        username: user.username,
        name: user.name,
        avatar_url: user.avatar_url,
        last_seen_at: user.last_seen_at
      }

      case Map.get(contacts_map, user.id) do
        nil ->
          base

        nickname ->
          Map.put(base, :contact_info, %{
            owner_user_id: asking_user_id,
            nickname: nickname
          })
      end
    end)
  end

  defp broadcast_user_status(user_id, is_online) do
    # Get the user to include last_seen_at
    user = User.get(user_id)

    payload = %{
      type: "user_status_changed",
      user_id: user_id,
      is_online: is_online,
      last_seen_at: user.last_seen_at
    }

    # Get users from contacts AND chat partners
    contact_users = Contacts.get_users_with_contact(user_id)
    chat_partners = Chat.get_chat_partners(user_id)

    # Combine and deduplicate
    relevant_users = Enum.uniq(contact_users ++ chat_partners)

    # Send only to online sessions
    Enum.each(relevant_users, fn relevant_user_id ->
      case ProcessRegistry.whereis_user_session(relevant_user_id) do
        nil -> :ok
        us_pid -> send_payload(us_pid, payload)
      end
    end)
  end

  ################### Calls

  @impl true
  def handle_call(:socket_alive?, _from, %{socket: socket} = state) do
    {:reply, socket != nil, state}
  end

  @impl true
  def handle_call(:logout, _from, state) do
    now = DateTime.utc_now() |> DateTime.truncate(:second)

    User.update_last_seen_at(state.user_id, now)

    broadcast_user_status(state.user_id, false)

    ProcessRegistry.unregister_user_session(state.user_id)
    {:stop, :normal, :ok, %{state | socket: nil}}
  end

  @impl true
  def terminate(reason, state) do
    if state.user_id != nil and reason != :normal do

      now = DateTime.utc_now() |> DateTime.truncate(:second)
      User.update_last_seen_at(state.user_id, now)

      broadcast_user_status(state.user_id, false)
    end
    :ok
  end

  ##################### HANDLE INFOS

  @impl true
  def handle_info({:EXIT, _socket_pid, _reason}, state) do
    ref = Process.send_after(self(), :disconnect_timeout, Constants.session_timeout())
    {:noreply, %{state | socket: nil, disconnect_timer: ref}}
  end

  @impl true
  def handle_info(:disconnect_timeout, state) do
    ProcessRegistry.unregister_user_session(state.user_id)
    {:stop, :normal, state}
  end

end
