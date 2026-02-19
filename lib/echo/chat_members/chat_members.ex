defmodule Echo.ChatMembers.ChatMembers do
  import Ecto.Query
  alias Echo.Repo
  alias Echo.Schemas.ChatMember
  alias Echo.Schemas.User, as: SchemaUser

  def set_last_read(user_id, chat_id) do
    from(cm in ChatMember,
      where: cm.user_id == ^user_id and cm.chat_id == ^chat_id
    )
    |> Repo.update_all(set: [last_read_at: DateTime.utc_now()])
  end

  def member?(chat_id, user_id) do
    Repo.exists?(
      from cm in Echo.Schemas.ChatMember,
        where: cm.chat_id == ^chat_id and cm.user_id == ^user_id
    )
  end

  @doc """
  Returns all members of a chat as a list of ChatMember structs,
  ordered by `inserted_at` ascending (oldest first).
  """
  def get_all_members(chat_id) do
    from(cm in ChatMember,
      where: cm.chat_id == ^chat_id,
      order_by: [asc: cm.inserted_at]
    )
    |> Repo.all()
  end

  def get_member_full(chat_id, user_id) do
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

  def get_role(chat_id, user_id) do
    from(cm in ChatMember,
      where: cm.chat_id == ^chat_id and cm.user_id == ^user_id,
      select: cm.role
    )
    |> Repo.one()
  end

end
