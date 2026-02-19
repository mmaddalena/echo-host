defmodule Echo.Chats.Chat do
  # Define la estructura del usuario con el schema
  # Llama a la DB para querys correspondientes a Usuarios

  # Funciones que (probablemente) usen Ecto...

  import Ecto.Query
  alias Echo.Repo
  alias Echo.Users.User
  alias Echo.Schemas.User, as: SchemaUser
  alias Echo.Schemas.Chat
  alias Echo.Schemas.ChatMember
  alias Echo.Schemas.Message
  alias Echo.Constants

  def get(chat_id) do
    Repo.get(Chat, chat_id)
  end

  def get_last_messages(chat_id) do
    from(m in Message,
      join: u in SchemaUser,
      on: u.id == m.user_id,
      where: m.chat_id == ^chat_id,
      where: is_nil(m.deleted_at),
      order_by: [desc: m.inserted_at, desc: m.id],
      limit: ^Constants.messages_page_size(),
      select: %{
        id: m.id,
        content: m.content,
        user_id: m.user_id,
        chat_id: m.chat_id,
        state: m.state,
        time: m.inserted_at,
        deleted_at: m.deleted_at,
        avatar_url: u.avatar_url,
        format: m.format,
        filename: m.filename
      }
    )
    |> Repo.all()
    |> Enum.reverse()
  end

  def search_messages(chat_id, query) do
    from(m in Message,
      where: m.chat_id == ^chat_id,
      where: ilike(m.content, ^"%#{query}%"),
      order_by: [asc: m.inserted_at],
      select: %{
        id: m.id,
        content: m.content,
        inserted_at: m.inserted_at
      }
    )
    |> Repo.all()
  end

  def get_members(chat_id) do
    from(cm in ChatMember,
      join: u in SchemaUser,
      on: u.id == cm.user_id,
      where: cm.chat_id == ^chat_id,
      select: %{
        user_id: u.id,
        username: u.username,
        name: u.name,
        avatar_url: u.avatar_url,
        last_read_at: cm.last_read_at,
        role: cm.role
      }
    )
    |> Repo.all()
  end


  def get_other_user_id(chat_id, user_id) do
    users =
      from(cm in ChatMember,
        join: c in Chat,
        on: c.id == cm.chat_id,
        where: cm.chat_id == ^chat_id and c.type == "private",
        select: cm.user_id
      )
      |> Repo.all()

    case users do
      [only_user] ->
        only_user

      [u1, u2] ->
        if u1 == user_id, do: u2, else: u1

      _ ->
        nil
    end
  end

  def get_avatar_url(chat, other_user_id) do
    case chat.type do
      "private" ->
        Repo.get!(SchemaUser, other_user_id).avatar_url

      _group ->
        chat.avatar_url
    end
  end

  def set_messages_read(chat_id, reader_user_id) do
    if Repo.get(Chat, chat_id).type == Constants.private_chat() do
      from(m in Message,
        where:
          m.chat_id == ^chat_id and
            m.user_id != ^reader_user_id and
            m.state != ^Constants.state_read()
      )
      |> Repo.update_all(set: [state: Constants.state_read()])
    end

    # Si implementamos el state en grupales ponemos un else aca y lo hacemos
  end


  def get_private_chat_id(user1_id, user2_id) when user1_id == user2_id do
    nil
  end
  def get_private_chat_id(user1_id, user2_id) do
    res = from(c in Chat,
      join: cm1 in ChatMember,
      on: cm1.chat_id == c.id,
      join: cm2 in ChatMember,
      on: cm2.chat_id == c.id,
      where:
      c.type == ^Constants.private_chat() and
      cm1.user_id == ^user1_id and
      cm2.user_id == ^user2_id,
      select: c.id,
      limit: 1
    )
    |> Repo.one()
    IO.puts("\n\n\n SE PASA EL PRIVATE CHATID DE #{user1_id} y #{user2_id}:\n Resultado: #{IO.inspect(res)} \n\n\n")
    res
  end

  def create_private_chat(creator_id, receiver_id) do
    case get_private_chat_id(creator_id, receiver_id) do
      nil ->
        Repo.transaction(fn ->
          {:ok, chat} =
            Chat.private_chat_changeset(creator_id)
            |> Repo.insert()

          Repo.insert!(%ChatMember{
            chat_id: chat.id,
            user_id: creator_id
          })

          if creator_id != receiver_id do
            Repo.insert!(%ChatMember{
              chat_id: chat.id,
              user_id: receiver_id
            })
          end

          chat.id
        end)
        |> case do
          {:ok, chat_id} -> chat_id
          {:error, reason} -> raise reason
        end

      chat_id ->
        IO.puts("\n\n\n\n YA ESTABA ESTE CHAT PRIVADO CREADO\n\n\n\n")
        chat_id
    end
  end


  def build_chat_info(chat_id, user_id) do
    chat = get(chat_id)

    is_private? = chat.type == Constants.private_chat()
    other_user_id = get_other_user_id(chat_id, user_id)

    IO.puts("\n\n\n\n El OTHER USER ID ES: #{other_user_id}\n\n\n\n")

    status =
      if is_private? do
        if User.is_active?(other_user_id),
          do: Constants.online(),
          else: Constants.offline()
      else
        nil
      end

    members =
      get_members(chat_id)
      |> Enum.map(fn m ->
        Map.put(m, :nickname, User.get_nickname(user_id, m.user_id))
      end)

    messages =
      chat_id
      |> get_last_messages()
      |> Enum.map(fn message ->
        type =
          if message.user_id == user_id,
            do: Constants.outgoing(),
            else: Constants.incoming()

        sender_name = User.get_usable_name(user_id, message.user_id, nil)

        message
        |> Map.put(:type, type)
        |> Map.put(:sender_name, sender_name)
      end)

    name = User.get_usable_name(user_id, other_user_id, chat.name)

    avatar_url = get_avatar_url(chat, other_user_id)

    if(is_private?) do
      %{
        id: chat_id,
        messages: messages ,
        name: name,
        status: status,
        type: chat.type,
        avatar_url: avatar_url,
        members: members
      }
    else
      %{
        id: chat_id,
        messages: messages ,
        name: name,
        description: chat.description,
        status: status,
        type: chat.type,
        avatar_url: avatar_url,
        members: members
      }
    end
  end

  def build_chat_list_item(chat_id, user_id) do
    chat = get(chat_id)

    case chat.type do
      "private" ->
        other_user_id = get_other_user_id(chat_id, user_id)
        other_user = Repo.get!(SchemaUser, other_user_id)

        name = User.get_usable_name(user_id, other_user_id, nil)

        status =
          if User.is_active?(other_user_id),
            do: Constants.online(),
            else: Constants.offline()

        %{
          id: chat.id,
          type: chat.type,
          name: name,
          avatar_url: other_user.avatar_url,
          status: status,
          unread_messages: 0,
          last_message: nil
        }

      "group" ->
        %{
          id: chat.id,
          type: chat.type,
          name: chat.name,
          avatar_url: chat.avatar_url,
          status: nil,
          unread_messages: 0,
          last_message: nil
        }
    end
  end

  @doc """
  Creates a group chat and its members.

  Returns {:ok, chat_id} or {:error, reason}
  """
  def create_group_chat(%{
        name: name,
        description: description,
        avatar_url: avatar_url,
        creator_id: creator_id,
        member_ids: member_ids
      }) do
    members =
      member_ids
      |> Enum.uniq()
      |> Enum.concat([creator_id])
      |> Enum.uniq()

    Repo.transaction(fn ->
      # 1️⃣ Create the group chat
      {:ok, chat} =
        %Chat{}
        |> Chat.changeset(%{
          type: "group",
          name: name,
          description: description,
          avatar_url: avatar_url,
          creator_id: creator_id
        })
        |> Repo.insert()

      # 2️⃣ Insert members
      Enum.each(members, fn user_id ->
        %ChatMember{}
        |> ChatMember.changeset(%{
          chat_id: chat.id,
          user_id: user_id,
          role: if(user_id == creator_id, do: "admin", else: "member")
        })
        |> Repo.insert!()
      end)

      chat.id
    end)
  end

  def remove_member(chat_id, requester_id, member_user_id) do
    Repo.transaction(fn ->
      with {:ok, _chat} <- get_chat(chat_id),
          {:ok, member} <- get_member(chat_id, member_user_id),
          {:ok, requester} <- get_member(chat_id, requester_id),
          true <- can_remove_member?(requester, member, requester_id) do

        # Get all remaining members (excluding the one leaving)
        remaining_members = Echo.ChatMembers.ChatMembers.get_all_members(chat_id)
                            |> Enum.reject(&(&1.user_id == member_user_id))

        # If leaving member is admin, assign admin to oldest member
        if member.role == "admin" && length(remaining_members) > 0 do
          oldest_member = Enum.min_by(remaining_members, & &1.inserted_at)
          Repo.update!(Ecto.Changeset.change(oldest_member, role: "admin"))

          # Broadcast the new admin
          Echo.Chats.ChatSession.broadcast(chat_id, %{
            type: "chat_admin_changed",
            chat_id: chat_id,
            new_admin_id: oldest_member.user_id
          })
        end

        # Remove the member
        Repo.delete!(member)

        # Broadcast member removal
        Echo.Chats.ChatSession.broadcast(chat_id, %{
          type: "chat_member_removed",
          chat_id: chat_id,
          user_id: member_user_id
        })

        {:ok, :removed}
      else
        false -> Repo.rollback({:error, :unauthorized})
        error -> Repo.rollback(error)
      end
    end)
    |> unwrap_tx()
  end

defp can_remove_member?(%{role: "admin"}, _member, _requester_id), do: true
defp can_remove_member?(%{role: _}, %{user_id: member_id}, requester_id) do
  member_id == requester_id  # regular user can only remove themselves
end

  defp get_chat(chat_id) do
    case Repo.get(Chat, chat_id) do
      nil -> {:error, :not_found}
      chat -> {:ok, chat}
    end
  end

  defp ensure_admin(chat, user_id) do
    query =
      from cm in ChatMember,
        where:
          cm.chat_id == ^chat.id and
            cm.user_id == ^user_id and
            cm.role == "admin"

    case Repo.exists?(query) do
      true -> :ok
      false -> {:error, :unauthorized}
    end
  end

  defp get_member(chat_id, member_user_id) do
    query =
      from cm in ChatMember,
        where:
          cm.chat_id == ^chat_id and
            cm.user_id == ^member_user_id

    case Repo.one(query) do
      nil -> {:error, :not_found}
      member -> {:ok, member}
    end
  end

  defp unwrap_tx({:ok, result}), do: result
  defp unwrap_tx({:error, reason}), do: {:error, reason}

  def add_members(chat_id, requester_id, member_ids) do
    result =
      Repo.transaction(fn ->
        with {:ok, chat} <- get_chat(chat_id),
            :ok <- ensure_admin(chat, requester_id) do
          Enum.each(member_ids, fn user_id ->
            add_member_to_chat(chat_id, user_id)
          end)

          {:ok, :added}
        else
          error -> Repo.rollback(error)
        end
      end)

    case unwrap_tx(result) do
      {:ok, :added} = ok ->
        Echo.Chats.ChatSession.broadcast(chat_id, %{
          type: "chat_members_added",
          chat_id: chat_id,
          added_user_ids: member_ids
        })

        ok

      error ->
        error
    end
  end

  defp add_member_to_chat(chat_id, user_id) do
    %ChatMember{}
    |> ChatMember.changeset(%{
      chat_id: chat_id,
      user_id: user_id,
      role: "member"
    })
    |> Repo.insert(on_conflict: :nothing)
  end


  def change_group_name(chat_id, new_name, changer_user_id) do
    Repo.transaction(fn ->
      with {:ok, chat} <- get_chat(chat_id),
          "group" <- chat.type || {:error, :not_a_group},
          :ok <- ensure_admin(chat, changer_user_id) do

        chat
        |> Chat.changeset(%{name: new_name})
        |> Repo.update()
      else
        {:error, reason} -> Repo.rollback(reason)
        {:error, _} = err -> Repo.rollback(err)
        _ -> Repo.rollback(:invalid_chat_type)
      end
    end)
    |> unwrap_tx_result()
  end

  def change_group_description(chat_id, new_description, changer_user_id) do
    Repo.transaction(fn ->
      with {:ok, chat} <- get_chat(chat_id),
          "group" <- chat.type || {:error, :not_a_group},
          :ok <- ensure_admin(chat, changer_user_id) do

        chat
        |> Chat.changeset(%{description: new_description})
        |> Repo.update()
      else
        {:error, reason} -> Repo.rollback(reason)
        {:error, _} = err -> Repo.rollback(err)
        _ -> Repo.rollback(:invalid_chat_type)
      end
    end)
    |> unwrap_tx_result()
  end

  def give_admin(chat_id, user_id, giving_user_id) do
    Repo.transaction(fn ->
      with {:ok, chat} <- get_chat(chat_id),
          "group" <- chat.type || {:error, :not_a_group},
          :ok <- ensure_admin(chat, giving_user_id),
          {:ok, target_member} <- get_member(chat_id, user_id) do

        {:ok, _} =
          target_member
          |> Ecto.Changeset.change(role: "admin")
          |> Repo.update()

        get_member_view(chat_id, user_id)   # <- map limpio
      else
        {:error, reason} -> Repo.rollback(reason)
        {:error, _} = err -> Repo.rollback(err)
        _ -> Repo.rollback(:invalid_chat_type)
      end
    end)
    |> unwrap_tx_result()
  end



  def get_member_view(chat_id, user_id) do
    from(cm in ChatMember,
      join: u in SchemaUser,
      on: u.id == cm.user_id,
      where: cm.chat_id == ^chat_id and u.id == ^user_id,
      select: %{
        user_id: u.id,
        username: u.username,
        name: u.name,
        avatar_url: u.avatar_url,
        last_read_at: cm.last_read_at,
        role: cm.role
      }
    )
    |> Repo.one()
  end



  defp unwrap_tx_result({:ok, {:ok, result}}), do: {:ok, result}

  defp unwrap_tx_result({:ok, result}), do: {:ok, result}

  defp unwrap_tx_result({:ok, {:error, changeset}}),
    do: {:error, %{name: User.format_changeset_error(changeset)}}
  defp unwrap_tx_result({:error, :not_found}),
    do: {:error, :not_found}
  defp unwrap_tx_result({:error, :not_a_group}),
    do: {:error, :not_found}
  defp unwrap_tx_result({:error, :invalid_chat_type}),
    do: {:error, :not_found}


  def update_group_avatar(chat_id, avatar_url) do
  result =
    Repo.transaction(fn ->
      case Repo.get(Chat, chat_id) do
        nil ->
          Repo.rollback(:not_found)

        chat ->
          case chat
               |> Ecto.Changeset.change(%{avatar_url: avatar_url})
               |> Repo.update() do
            {:ok, _chat} ->
              {:ok, avatar_url}

            {:error, changeset} ->
              Repo.rollback(changeset)
          end
      end
    end)

  case unwrap_tx_result(result) do
    {:ok, avatar_url} = ok ->
      Echo.Chats.ChatSession.broadcast(chat_id, %{
        type: "group_avatar_updated",
        chat_id: chat_id,
        avatar_url: avatar_url
      })

      ok

    error ->
      error
  end
end
end
