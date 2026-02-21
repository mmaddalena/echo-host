defmodule Echo.Users.User do
  # Llama a la DB para querys correspondientes a Usuarios

  # Funciones que (probablemente) usen Ecto...

  import Ecto.Query
  alias Echo.Repo
  alias Echo.Contacts.Contacts
  alias Echo.ProcessRegistry
  alias Echo.Schemas.User, as: UserSchema
  alias Echo.Schemas.Chat, as: ChatSchema
  alias Echo.Chats.Chat
  alias Echo.Schemas.ChatMember
  alias Echo.Schemas.Contact
  alias Echo.Schemas.Message
  alias Echo.Constants
  alias Plug.Upload

  def get(id) do
    Repo.get(UserSchema, id)
  end

  def get_name(user_id) do
    case Repo.get(UserSchema, user_id) do
      nil -> nil
      user -> user.name
    end
  end

  def get_by_username(username) do
    Repo.get_by(UserSchema, username: username)
  end

  def get_avatar_url(user_id) do
    case Repo.get(UserSchema, user_id) do
      nil -> nil
      user -> user.avatar_url
    end
  end

  def update_username(user_id, new_username) do
    user = Repo.get(UserSchema, user_id)

    case user do
      nil ->
        {:error, :not_found}

      user ->
        user
        |> UserSchema.changeset(%{username: new_username})
        |> Repo.update()

        # Devuelve {:ok, %User{}} o {:error, %Ecto.Changeset{}}
    end
  end

  def change_password(user_id, new_pw) do
    user = Repo.get(UserSchema, user_id)

    case user do
      nil ->
        {:error, :not_found}

      user ->
        user
        |> UserSchema.registration_changeset(%{password: new_pw})
        |> Repo.update()

        # Devuelve {:ok, %User{}} o {:error, %Ecto.Changeset{}}
    end
  end

  def create(attrs) do
    %UserSchema{}
    |> UserSchema.registration_changeset(attrs)
    |> Repo.insert()
  end

  # Devuelve un array de maps de chats que contienen:
  # {
  #    "id": "chat_3",
  #    "name": "Manu",
  #    "type": "grupal|MD",
  #    "avatar_url: "https://cdn.echo.app/avatars/user_8f3a21c9.png"
  #    "unread_messages": 8
  #    "last_message": {
  #      "type": "incoming",
  #      "content": "Ahí voy",
  #      "state": "delivered",
  #      "time": "2026-01-09T12:10:00Z"
  #    },
  #  }
  def last_chats(user_id) do
    private_chats(user_id) ++ group_chats(user_id)
  end

  defp private_chats(user_id) do
    from(chat in ChatSchema,
      join: cm in ChatMember,
      on: cm.chat_id == chat.id,
      where: cm.user_id == ^user_id and chat.type == "private",

      left_join: other_cm in ChatMember,
      on: other_cm.chat_id == chat.id and other_cm.user_id != ^user_id,

      left_join: other_user in UserSchema,
      on: other_user.id == other_cm.user_id,

      join: self_user in UserSchema,
      on: self_user.id == ^user_id,

      left_join: contact in Contact,
      on: contact.user_id == ^user_id and contact.contact_id == other_user.id,

      select: %{
        id: chat.id,
        type: chat.type,
        name:
          fragment(
            "COALESCE(?, ?, ?, ?, ?)",
            contact.nickname,
            other_user.name,
            other_user.username,
            self_user.name,
            self_user.username
          ),
        avatar_url: fragment("COALESCE(?, ?)", other_user.avatar_url, self_user.avatar_url),
        other_user_id: fragment("COALESCE(?, ?)", other_user.id, self_user.id)
      }
    )
    |> Repo.all()
    |> Enum.map(fn chat ->
      chat
      |> Map.put(
        :status,
        if(is_active?(chat.other_user_id), do: Constants.online(), else: Constants.offline())
      )
      |> Map.delete(:other_user_id)
      |> Map.put(:unread_messages, Chat.get_unread_messages(user_id, chat.id))
      |> Map.put(:last_message, get_last_message(user_id, chat.id))
    end)
  end

  defp group_chats(user_id) do
    from(chat in ChatSchema,
      join: cm in ChatMember,
      on: cm.chat_id == chat.id,
      where: cm.user_id == ^user_id and chat.type == "group",
      distinct: chat.id,
      select: %{
        id: chat.id,
        type: chat.type,
        name: chat.name,
        avatar_url: chat.avatar_url
      }
    )
    |> Repo.all()
    |> Enum.map(fn chat ->
      chat
      |> Map.put(:status, nil)
      |> Map.put(:unread_messages, Chat.get_unread_messages(user_id, chat.id))
      |> Map.put(:last_message, get_last_message(user_id, chat.id))
    end)
  end

  def user_payload(user) do
    %{
      id: user.id,
      username: user.username,
      name: user.name,
      email: user.email,
      avatar_url: user.avatar_url,
      last_seen_at: user.last_seen_at
    }
  end

  def is_active?(user_id) do
    case ProcessRegistry.whereis_user_session(user_id) do
      nil ->
        false

      _ ->
        IO.inspect("User #{user_id} is active")
        # if (UserSession.has_socket(pid))
        true
    end
  end

  defp get_last_message(user_id, chat_id) do
    query =
      from m in Message,
        join: sender in UserSchema,
        on: sender.id == m.user_id,
        where: m.chat_id == type(^chat_id, :binary_id),
        where: is_nil(m.deleted_at),
        order_by: [desc: m.inserted_at],
        limit: 1,
        select: %{
          # Usa type() dentro del fragment también
          type:
            fragment(
              "CASE WHEN ? = ? THEN 'outgoing' ELSE 'incoming' END",
              m.user_id,
              type(^user_id, :binary_id)
            ),
          content: m.content,
          state: m.state,
          time: m.inserted_at,
          sender_name: sender.username,
          format: m.format,
          filename: m.filename
        }

    Repo.one(query)
  end

  # Chat grupal
  def get_usable_name(_user_id, nil, chat_name) do
    chat_name
  end

  # Mismo usuario
  def get_usable_name(user_id, user_id, _chat_name) do
    user = Repo.get!(UserSchema, user_id)
    user.name || user.username
  end

  # Chat privado
  def get_usable_name(user_id, other_user_id, _chat_name) do
    from(c in Contact,
      where: c.user_id == ^user_id and c.contact_id == ^other_user_id,
      select: c.nickname
    )
    |> Repo.one()
    |> case do
      nil ->
        other = Repo.get!(UserSchema, other_user_id)
        other.name || other.username

      nickname ->
        nickname
    end
  end

  def get_usable_names(user_id, other_users_ids) when is_list(other_users_ids) do
    nicknames =
      from(c in Contact,
        where: c.user_id == ^user_id and c.contact_id in ^other_users_ids,
        select: {c.contact_id, c.nickname}
      )
      |> Repo.all()
      |> Map.new()

    missing_ids =
      other_users_ids
      |> Enum.reject(&Map.has_key?(nicknames, &1))

    users =
      from(u in UserSchema,
        where: u.id in ^missing_ids,
        select: {u.id, coalesce(u.name, u.username)}
      )
      |> Repo.all()
      |> Map.new()

    Map.merge(users, nicknames)
  end

  def get_nickname(user_id, other_user_id) do
    from(c in Contact,
      where: c.user_id == ^user_id and c.contact_id == ^other_user_id,
      select: c.nickname
    )
    |> Repo.one()
    |> case do
      nil ->
        nil
      nickname ->
        nickname
    end
  end

  def update_avatar(user_id, avatar_url) do
    case Repo.get(UserSchema, user_id) do
      nil ->
        {:error, :not_found}

      user ->
        user
        |> Ecto.Changeset.change(%{avatar_url: avatar_url})
        |> Repo.update()
    end
  end

  @avatar_dir "priv/static/uploads/avatars"
  @allowed_types ~w(image/jpeg image/png image/webp)
  # 2MB
  @max_avatar_size 2_000_000

  def handle_avatar(nil), do: {:ok, nil}

  def handle_avatar(%Upload{} = upload) do
    with :ok <- validate_avatar(upload),
         {:ok, url} <- store_avatar(upload) do
      IO.inspect(url, label: "Avatar URL after upload")
      {:ok, url}
    end
  end

  def handle_avatar(_), do: {:error, :invalid_avatar}

  defp validate_avatar(%Upload{content_type: type, path: path})
       when type in @allowed_types do
    if File.stat!(path).size <= @max_avatar_size do
      :ok
    else
      {:error, :avatar_too_large}
    end
  end

  defp validate_avatar(_), do: {:error, :invalid_avatar_type}

  defp store_avatar(%Upload{} = upload) do
    File.mkdir_p!(@avatar_dir)

    # 2️⃣ Upload to GCP using existing Media module
    case Echo.Media.upload_register_avatar(upload) do
      {:ok, url} ->
        {:ok, url}

      {:error, reason} ->
        IO.inspect(reason, label: "Avatar upload error")
        {:error, reason}
    end
  end


  def get_person_info(person_id, asking_user_id) do
    case Repo.get(UserSchema, person_id) do
      nil ->
        :error

      user ->
        contact =
          Echo.Contacts.Contacts.get_contact_between(
            asking_user_id,
            person_id
          )

        status =
          if is_active?(person_id),
            do: Constants.online(),
            else: Constants.offline()

        base_payload = %{
          id: user.id,
          username: user.username,
          name: user.name,
          avatar_url: user.avatar_url,
          status: status,
          last_seen_at: user.last_seen_at,
          private_chat_id: Chat.get_private_chat_id(person_id, asking_user_id)
        }

        if contact do
          Map.put(base_payload,
            :contact_info, %{
              owner_user_id: contact.user_id,
              nickname: contact.nickname,
              added_at: contact.inserted_at
            }
          )
        else
          base_payload
        end
    end
  end

  def update_last_seen_at(user_id, datetime) do
    case Repo.get(UserSchema, user_id) do
      nil -> {:error, :not_found}
      user ->
        user
        |> Ecto.Changeset.change(last_seen_at: datetime)
        |> Repo.update()
    end
    IO.inspect("\n\nUSER LAST_SEEN_AT UPDATED TO: #{datetime}")
  end

  def search_users(asking_user, input) do
    query =
      input
      |> String.downcase()
      |> String.trim()

    if query == "" do
      []
    else
      users = search_users_by_text(query)

      contacts_map = Contacts.get_contacts_map(asking_user)

      users
      |> Enum.map(fn user ->
        score = base_score(user, query)

        score =
          case Map.get(contacts_map, user.id) do
            nil -> score
            nickname -> score + nickname_score(nickname, query)
          end

        {score, user}
      end)
      |> Enum.filter(fn {score, _} -> score > 0 end)
      |> Enum.sort_by(fn {score, _} -> -score end)
      |> Enum.take(Constants.max_search_results())
      |> Enum.map(fn {_, user} -> user end)
    end
  end

  defp search_users_by_text(query) do
    like = "%#{query}%"

    from(u in UserSchema,
      where:
        ilike(u.username, ^like) or
        ilike(u.name, ^like),
      limit: ^Constants.max_search_results() * 3
    )
    |> Repo.all()
  end


  defp base_score(user, query) do
    username = String.downcase(user.username)
    name = user.name && String.downcase(user.name)

    cond do
      String.starts_with?(username, query) -> 100
      name && String.starts_with?(name, query) -> 80
      String.contains?(username, query) -> 50
      name && String.contains?(name, query) -> 30
      true -> 0
    end
  end


  defp nickname_score(nickname, query) do
    nick = String.downcase(nickname)

    cond do
      String.starts_with?(nick, query) -> 150
      String.contains?(nick, query) -> 90
      true -> 0
    end
  end


  def change_username(user_id, new_username) do
    case Repo.get(UserSchema, user_id) do
      nil ->
        {:error, :not_found}

      user ->
        user
        |> UserSchema.username_changeset(%{username: new_username})
        |> Repo.update()
        |> case do
          {:ok, _updated_user} ->
            :ok

          {:error, changeset} ->
            {:error, format_changeset_error(changeset)}
        end
    end
  end

  def change_name(user_id, new_name) do
    case Repo.get(UserSchema, user_id) do
      nil ->
        {:error, :not_found}

      user ->
        user
        |> UserSchema.name_changeset(%{name: new_name})
        |> Repo.update()
        |> case do
          {:ok, user} ->
            {:ok, user}

          {:error, changeset} ->
            {:error, format_changeset_error(changeset)}
        end
    end
  end


  def format_changeset_error(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, _opts} -> msg end)
    |> Enum.map(fn {field, [error | _]} ->
      {field, error}
    end)
    |> Map.new()
  end

  def change_nickname(user_id, contact_id, new_nickname) do
    case Repo.get_by(Contact, user_id: user_id, contact_id: contact_id) do
      nil ->
        {:error, :contact_not_found}

      contact ->
        contact
        |> Contact.changeset(%{nickname: new_nickname})
        |> Repo.update()
        |> case do
          {:ok, _updated_contact} ->
            :ok

          {:error, changeset} ->
            {:error, format_changeset_error(changeset)}
        end
    end
  end



end
