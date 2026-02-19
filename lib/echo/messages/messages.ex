
defmodule Echo.Messages.Messages do
  alias Echo.Repo
  alias Echo.Schemas.{Message, ChatMember}
  alias Echo.Constants
  import Ecto.Query

  def create_message(attrs) do
    %Message{}
    |> Message.changeset(attrs)
    |> Repo.insert()
  end

  def get_sent_messages_for_user(user_id) do
    from(m in Message,
      join: cm in ChatMember, on: cm.chat_id == m.chat_id,
      join: c in Echo.Schemas.Chat, on: c.id == m.chat_id,
      where:
        cm.user_id == ^user_id and
        m.user_id != ^user_id and
        m.state == ^Constants.state_sent() and
        c.type == "private"
    )
    |> Repo.all()
  end

  def mark_delivered_for_user(user_id) do
    from(m in Message,
      join: cm in ChatMember, on: cm.chat_id == m.chat_id,
      join: c in Echo.Schemas.Chat, on: c.id == m.chat_id,
      where:
        cm.user_id == ^user_id and
        m.user_id != ^user_id and
        m.state == ^Constants.state_sent() and
        c.type == "private"
    )
    |> Repo.update_all(set: [state: Constants.state_delivered()])
  end

end
