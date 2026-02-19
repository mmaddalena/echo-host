defmodule Echo.Factory do
  @moduledoc """
  Test factory for generating test data
  """

  alias Echo.Repo
  alias Echo.Schemas.{User, Contact, Chat, ChatMember, Message, BlockedContact}

  defp generate_binary_id do
    Ecto.UUID.generate()
  end

  defp truncate_datetime(datetime) do
    DateTime.truncate(datetime, :second)
  end

  def insert(factory_name, attrs \\ %{}) do
    factory_name |> build(attrs) |> Repo.insert!()
  end

  def build(:user, attrs) do
    unique_num = System.unique_integer([:positive])
    username = Map.get(attrs, :username, "user_#{System.unique_integer([:positive])}")
    password = Map.get(attrs, :password, "12345678")
    email = Map.get(attrs, :email, "#{username}@example.com")

    %User{
      username: username,
      password_hash: password,
      name: Map.get(attrs, :name, "Test User #{unique_num}"),
      email: email,
      avatar_url: Map.get(attrs, :avatar_url),
      last_seen_at: Map.get(attrs, :last_seen_at, truncate_datetime(DateTime.utc_now()))
    }
    |> Map.merge(attrs)
  end

  def build(:chat, attrs) do
    # Handle creator_id - can be passed directly or we'll create a user
    creator_id = case Map.get(attrs, :creator_id) do
      nil ->
        user = insert(:user)
        user.id
      id when is_binary(id) -> id
      %User{id: id} -> id
    end

    %Chat{
      id: Map.get(attrs, :id) || generate_binary_id(),
      name: Map.get(attrs, :name, "Test Chat #{System.unique_integer([:positive])}"),
      description: Map.get(attrs, :description, "This is a test chat"),
      type: Map.get(attrs, :type, "private"),
      avatar_url: Map.get(attrs, :avatar_url),
      creator_id: creator_id
    }
    |> Map.merge(attrs)
  end

  def build(:chat_member, attrs) do
    %ChatMember{
      chat_id: Map.get(attrs, :chat_id) || insert(:chat).id,
      user_id: Map.get(attrs, :user_id) || insert(:user).id,
      role: Map.get(attrs, :role, "member"),
      inserted_at: Map.get(attrs, :inserted_at, truncate_datetime(DateTime.utc_now()))
    }
    |> Map.merge(attrs)
  end

  def build(:message, attrs) do
    %Message{
      chat_id: Map.get(attrs, :chat_id) || insert(:chat).id,
      user_id: Map.get(attrs, :user_id) || insert(:user).id,
      content: Map.get(attrs, :content, "Test message"),
      state: Map.get(attrs, :state, :sent),
      inserted_at: Map.get(attrs, :inserted_at, truncate_datetime(DateTime.utc_now()))
    }
    |> Map.merge(attrs)
  end

  def build(:contact, attrs) do
  # Handle user_id - can be passed directly or we'll create a user
  user_id = case Map.get(attrs, :user_id) do
    nil ->
      user = insert(:user)
      user.id
    id when is_binary(id) -> id
    %User{id: id} -> id
  end

  # Handle contact_id - can be passed directly or we'll create a user
  contact_id = case Map.get(attrs, :contact_id) do
    nil ->
      user = insert(:user)
      user.id
    id when is_binary(id) -> id
    %User{id: id} -> id
  end

  # Ensure user_id and contact_id are different
  final_user_id = user_id
  final_contact_id = if user_id == contact_id do
    # If they're the same, create a new user for contact
    insert(:user).id
  else
    contact_id
  end

  %Contact{
    id: Map.get(attrs, :id) || generate_binary_id(),
    user_id: final_user_id,
    contact_id: final_contact_id,
    nickname: Map.get(attrs, :nickname),
    inserted_at: Map.get(attrs, :inserted_at, truncate_datetime(DateTime.utc_now()))
  }
  |> Map.merge(attrs)
end
end
