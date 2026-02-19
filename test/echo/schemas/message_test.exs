defmodule Echo.Schemas.MessageTest do
  use Echo.DataCase, async: true

  alias Echo.Schemas.{Message, User, Chat}

  defp valid_user do
    %User{
      id: Ecto.UUID.generate(),
      username: "user1",
      email: "user1@test.com",
      password_hash: "hash",
      name: "User One"
    }
  end

  defp valid_chat do
    %Chat{
      id: Ecto.UUID.generate(),
      name: "Test chat"
    }
  end

  defp valid_attrs(user_id, chat_id) do
    %{
      content: "hello",
      user_id: user_id,
      chat_id: chat_id
    }
  end

  # -----------------------------
  # changeset/2
  # -----------------------------
  describe "changeset/2" do
    test "valid message" do
      user = valid_user()
      chat = valid_chat()

      changeset =
        Message.changeset(%Message{}, valid_attrs(user.id, chat.id))

      assert changeset.valid?
    end

    test "requires content" do
      user = valid_user()
      chat = valid_chat()

      changeset =
        Message.changeset(%Message{}, %{
          user_id: user.id,
          chat_id: chat.id
        })

      refute changeset.valid?
      assert :content in Map.keys(errors_on(changeset))
    end

    test "requires user_id" do
      chat = valid_chat()

      changeset =
        Message.changeset(%Message{}, %{
          content: "hi",
          chat_id: chat.id
        })

      refute changeset.valid?
      assert :user_id in Map.keys(errors_on(changeset))
    end

    test "requires chat_id" do
      user = valid_user()

      changeset =
        Message.changeset(%Message{}, %{
          content: "hi",
          user_id: user.id
        })

      refute changeset.valid?
      assert :chat_id in Map.keys(errors_on(changeset))
    end

    test "content too short" do
      user = valid_user()
      chat = valid_chat()

      changeset =
        Message.changeset(%Message{}, %{
          content: "",
          user_id: user.id,
          chat_id: chat.id
        })

      refute changeset.valid?
    end

    test "content too long" do
      user = valid_user()
      chat = valid_chat()

      long_content = String.duplicate("a", 6000)

      changeset =
        Message.changeset(%Message{}, %{
          content: long_content,
          user_id: user.id,
          chat_id: chat.id
        })

      refute changeset.valid?
    end

    test "valid state" do
      user = valid_user()
      chat = valid_chat()

      changeset =
        Message.changeset(%Message{}, %{
          content: "hello",
          user_id: user.id,
          chat_id: chat.id,
          state: :read
        })

      assert changeset.valid?
    end

    test "invalid state" do
      user = valid_user()
      chat = valid_chat()

      changeset =
        Message.changeset(%Message{}, %{
          content: "hello",
          user_id: user.id,
          chat_id: chat.id,
          state: :invalid
        })

      refute changeset.valid?
      assert :state in Map.keys(errors_on(changeset))
    end

    test "valid formats" do
      user = valid_user()
      chat = valid_chat()

      for format <- ["text", "image", "video", "audio", "file"] do
        changeset =
          Message.changeset(%Message{}, %{
            content: "hello",
            user_id: user.id,
            chat_id: chat.id,
            format: format
          })

        assert changeset.valid?
      end
    end

    test "invalid format" do
      user = valid_user()
      chat = valid_chat()

      changeset =
        Message.changeset(%Message{}, %{
          content: "hello",
          user_id: user.id,
          chat_id: chat.id,
          format: "unknown"
        })

      refute changeset.valid?
      assert :format in Map.keys(errors_on(changeset))
    end
  end

  # -----------------------------
  # soft delete
  # -----------------------------
  describe "soft_delete_changeset/1" do
    test "sets deleted_at timestamp" do
      message = %Message{}
      changeset = Message.soft_delete_changeset(message)

      assert changeset.valid?
      assert get_change(changeset, :deleted_at)
    end
  end
end
