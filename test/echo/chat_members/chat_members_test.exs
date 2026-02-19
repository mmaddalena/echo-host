defmodule Echo.ChatMembers.ChatMembersTest do
  use Echo.DataCase, async: true

  alias Echo.ChatMembers.ChatMembers
  alias Echo.Schemas.{ChatMember, User, Chat}

  import Echo.Factory

  describe "set_last_read/2" do
    setup do
      user = insert(:user)
      chat = insert(:chat)
      insert(:chat_member, %{chat_id: chat.id, user_id: user.id})

      %{user: user, chat: chat}
    end

    test "updates last_read_at for the chat member", %{user: user, chat: chat} do
      # Get initial state
      initial_member = Repo.get_by(ChatMember, chat_id: chat.id, user_id: user.id)
      assert is_nil(initial_member.last_read_at)

      Process.sleep(1000)

      # Call the function
      {1, nil} = ChatMembers.set_last_read(user.id, chat.id)

      # Verify update
      updated_member = Repo.get_by(ChatMember, chat_id: chat.id, user_id: user.id)
      refute is_nil(updated_member.last_read_at)
      assert DateTime.compare(updated_member.last_read_at, initial_member.inserted_at) == :gt
    end

    test "returns {0, nil} when member doesn't exist", %{chat: chat} do
      non_existent_user_id = Ecto.UUID.generate()

      {0, nil} = ChatMembers.set_last_read(non_existent_user_id, chat.id)
    end

    test "returns {0, nil} when chat doesn't exist", %{user: user} do
      non_existent_chat_id = Ecto.UUID.generate()

      {0, nil} = ChatMembers.set_last_read(user.id, non_existent_chat_id)
    end

    test "updates only the specified member when multiple members exist", %{user: user} do
      other_user = insert(:user)
      chat = insert(:chat)

      insert(:chat_member, %{chat_id: chat.id, user_id: user.id})
      insert(:chat_member, %{chat_id: chat.id, user_id: other_user.id})

      # Update only the first user
      {1, nil} = ChatMembers.set_last_read(user.id, chat.id)

      # Verify first user was updated
      member1 = Repo.get_by(ChatMember, chat_id: chat.id, user_id: user.id)
      refute is_nil(member1.last_read_at)

      # Verify second user was NOT updated
      member2 = Repo.get_by(ChatMember, chat_id: chat.id, user_id: other_user.id)
      assert is_nil(member2.last_read_at)
    end
  end

  describe "member?/2" do
    setup do
      user = insert(:user)
      chat = insert(:chat)

      %{user: user, chat: chat}
    end

    test "returns true when user is a member", %{user: user, chat: chat} do
      insert(:chat_member, %{chat_id: chat.id, user_id: user.id})

      assert ChatMembers.member?(chat.id, user.id) == true
    end

    test "returns false when user is not a member", %{user: user, chat: chat} do
      # No member inserted

      assert ChatMembers.member?(chat.id, user.id) == false
    end

    test "returns false for non-existent chat", %{user: user} do
      non_existent_chat_id = Ecto.UUID.generate()

      assert ChatMembers.member?(non_existent_chat_id, user.id) == false
    end

    test "returns false for non-existent user", %{chat: chat} do
      non_existent_user_id = Ecto.UUID.generate()

      assert ChatMembers.member?(chat.id, non_existent_user_id) == false
    end

    test "correctly identifies membership when multiple users exist" do
      user1 = insert(:user)
      user2 = insert(:user)
      chat = insert(:chat)

      insert(:chat_member, %{chat_id: chat.id, user_id: user1.id})
      # user2 is not a member

      assert ChatMembers.member?(chat.id, user1.id) == true
      assert ChatMembers.member?(chat.id, user2.id) == false
    end
  end

  describe "get_all_members/1" do
    setup do
      chat = insert(:chat)

      %{chat: chat}
    end

    test "returns all members ordered by inserted_at asc", %{chat: chat} do
      user1 = insert(:user)
      user2 = insert(:user)
      user3 = insert(:user)

      # Insert in non-chronological order
      member2 = insert(:chat_member, %{
        chat_id: chat.id,
        user_id: user2.id,
        inserted_at: DateTime.utc_now() |> DateTime.add(-10, :second) |> DateTime.truncate(:second)
      })
      member3 = insert(:chat_member, %{
        chat_id: chat.id,
        user_id: user3.id,
        inserted_at: DateTime.utc_now() |> DateTime.add(-5, :second) |> DateTime.truncate(:second)
      })
      member1 = insert(:chat_member, %{
        chat_id: chat.id,
        user_id: user1.id,
        inserted_at: DateTime.utc_now() |> DateTime.add(-15, :second) |> DateTime.truncate(:second)
      })

      members = ChatMembers.get_all_members(chat.id)

      assert length(members) == 3

      # Compare by user_id and chat_id instead of id
      assert List.first(members).user_id == member1.user_id
      assert List.first(members).chat_id == member1.chat_id

      assert Enum.at(members, 1).user_id == member2.user_id
      assert Enum.at(members, 1).chat_id == member2.chat_id

      assert List.last(members).user_id == member3.user_id
      assert List.last(members).chat_id == member3.chat_id
    end

    test "returns empty list when chat has no members", %{chat: chat} do
      members = ChatMembers.get_all_members(chat.id)

      assert members == []
    end

    test "returns empty list for non-existent chat" do
      non_existent_chat_id = Ecto.UUID.generate()

      members = ChatMembers.get_all_members(non_existent_chat_id)

      assert members == []
    end

    test "returns only members of the specified chat" do
      chat1 = insert(:chat)
      chat2 = insert(:chat)

      user1 = insert(:user)
      user2 = insert(:user)

      member1 = insert(:chat_member, %{chat_id: chat1.id, user_id: user1.id})
      insert(:chat_member, %{chat_id: chat2.id, user_id: user2.id})

      members = ChatMembers.get_all_members(chat1.id)

      assert length(members) == 1

      # Compare by user_id and chat_id instead of id
      first_member = List.first(members)
      assert first_member.user_id == member1.user_id
      assert first_member.chat_id == member1.chat_id
    end
  end

  describe "get_member_full/2" do
    setup do
      user = insert(:user, %{username: "testuser", name: "Test User", avatar_url: "http://example.com/avatar.jpg"})
      chat = insert(:chat)
      member = insert(:chat_member, %{
        chat_id: chat.id,
        user_id: user.id,
        role: "admin",
        last_read_at: DateTime.utc_now() |> DateTime.truncate(:second)
      })

      %{user: user, chat: chat, member: member}
    end

    test "returns full member info with user details", %{user: user, chat: chat, member: member} do
      result = ChatMembers.get_member_full(chat.id, user.id)

      assert result.user_id == user.id
      assert result.username == user.username
      assert result.name == user.name
      assert result.avatar_url == user.avatar_url
      assert result.role == "admin"
      assert result.last_read_at == member.last_read_at
    end

    test "returns nil when user is not a member", %{chat: chat} do
      non_member = insert(:user)

      result = ChatMembers.get_member_full(chat.id, non_member.id)

      assert is_nil(result)
    end

    test "returns nil when chat doesn't exist", %{user: user} do
      non_existent_chat_id = Ecto.UUID.generate()

      result = ChatMembers.get_member_full(non_existent_chat_id, user.id)

      assert is_nil(result)
    end

    test "returns nil when user doesn't exist", %{chat: chat} do
      non_existent_user_id = Ecto.UUID.generate()

      result = ChatMembers.get_member_full(chat.id, non_existent_user_id)

      assert is_nil(result)
    end

    test "returns correct role for different member types" do
      chat = insert(:chat)
      creator = insert(:user)
      admin = insert(:user)
      member = insert(:user)

      insert(:chat_member, %{chat_id: chat.id, user_id: creator.id, role: "creator"})
      insert(:chat_member, %{chat_id: chat.id, user_id: admin.id, role: "admin"})
      insert(:chat_member, %{chat_id: chat.id, user_id: member.id, role: "member"})

      creator_result = ChatMembers.get_member_full(chat.id, creator.id)
      assert creator_result.role == "creator"

      admin_result = ChatMembers.get_member_full(chat.id, admin.id)
      assert admin_result.role == "admin"

      member_result = ChatMembers.get_member_full(chat.id, member.id)
      assert member_result.role == "member"
    end

    test "handles nil last_read_at correctly" do
      user = insert(:user)
      chat = insert(:chat)
      insert(:chat_member, %{chat_id: chat.id, user_id: user.id, role: "member", last_read_at: nil})

      result = ChatMembers.get_member_full(chat.id, user.id)

      assert result.user_id == user.id
      assert is_nil(result.last_read_at)
    end
  end

  describe "get_role/2" do
    setup do
      user = insert(:user)
      chat = insert(:chat)

      %{user: user, chat: chat}
    end

    test "returns the correct role for a member", %{user: user, chat: chat} do
      insert(:chat_member, %{chat_id: chat.id, user_id: user.id, role: "admin"})

      role = ChatMembers.get_role(chat.id, user.id)

      assert role == "admin"
    end

    test "returns nil when user is not a member", %{chat: chat} do
      non_member = insert(:user)

      role = ChatMembers.get_role(chat.id, non_member.id)

      assert is_nil(role)
    end

    test "returns nil when chat doesn't exist", %{user: user} do
      non_existent_chat_id = Ecto.UUID.generate()

      role = ChatMembers.get_role(non_existent_chat_id, user.id)

      assert is_nil(role)
    end

    test "returns nil when user doesn't exist", %{chat: chat} do
      non_existent_user_id = Ecto.UUID.generate()

      role = ChatMembers.get_role(chat.id, non_existent_user_id)

      assert is_nil(role)
    end

    test "returns different roles for different members" do
      chat = insert(:chat)
      admin = insert(:user)
      member = insert(:user)

      insert(:chat_member, %{chat_id: chat.id, user_id: admin.id, role: "admin"})
      insert(:chat_member, %{chat_id: chat.id, user_id: member.id, role: "member"})

      assert ChatMembers.get_role(chat.id, admin.id) == "admin"
      assert ChatMembers.get_role(chat.id, member.id) == "member"
    end
  end

  describe "integration tests" do
    test "multiple operations work together correctly" do
      # Create test data
      user = insert(:user)
      chat = insert(:chat)

      # Initially user is not a member
      refute ChatMembers.member?(chat.id, user.id)
      assert is_nil(ChatMembers.get_role(chat.id, user.id))
      assert [] == ChatMembers.get_all_members(chat.id)

      # Add user as member
      member = insert(:chat_member, %{chat_id: chat.id, user_id: user.id, role: "member"})

      # Verify membership
      assert ChatMembers.member?(chat.id, user.id)
      assert ChatMembers.get_role(chat.id, user.id) == "member"
      assert [retrieved_member] = ChatMembers.get_all_members(chat.id)
      assert retrieved_member.user_id == member.user_id
      assert retrieved_member.chat_id == member.chat_id

      # Get full member info
      full_info = ChatMembers.get_member_full(chat.id, user.id)
      assert full_info.user_id == user.id
      assert full_info.username == user.username
      assert full_info.role == "member"
      assert is_nil(full_info.last_read_at)

      # Update last read
      {1, nil} = ChatMembers.set_last_read(user.id, chat.id)

      # Verify last read was updated
      updated_info = ChatMembers.get_member_full(chat.id, user.id)
      refute is_nil(updated_info.last_read_at)
    end
  end
end
