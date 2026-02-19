defmodule Echo.Users.UserSessionTest do
  use Echo.DataCase, async: false

  alias Echo.Users.UserSession
  alias Echo.Chats.Chat
  alias Echo.Constants

  import Echo.Factory

  setup do
    Ecto.Adapters.SQL.Sandbox.mode(Echo.Repo, {:shared, self()})

    :ok
  end

  describe "chat operations" do
    setup do
      user = insert(:user)
      other_user = insert(:user)
      chat = insert(:chat, %{type: "private", creator_id: user.id})
      # Add both users as members
      insert(:chat_member, %{chat_id: chat.id, user_id: user.id})
      insert(:chat_member, %{chat_id: chat.id, user_id: other_user.id})

      {:ok, pid} = UserSession.start_link(user.id)
      UserSession.login(pid, self())
      :timer.sleep(100)
      flush_user_info()
      %{pid: pid, user: user, other_user: other_user, chat: chat}
    end

    test "open_chat succeeds when user is member", %{pid: pid, chat: chat} do
      UserSession.open_chat(pid, chat.id)

      # Should receive chat_info
      assert_receive {:send, payload}
      assert payload.type == "chat_info"
      assert payload.chat.id == chat.id
    end

    test "open_chat fails when user is not member", %{pid: pid, user: user} do
      # Create chat where user is NOT a member
      other_user = insert(:user)
      forbidden_chat = insert(:chat, %{type: "private", creator_id: other_user.id})
      insert(:chat_member, %{chat_id: forbidden_chat.id, user_id: other_user.id})

      UserSession.open_chat(pid, forbidden_chat.id)

      assert_receive {:send, payload}
      assert payload.type == "chat_forbidden"
      assert payload.chat_id == forbidden_chat.id
    end
  end

  describe "contact operations" do
    setup do
      user = insert(:user)
      contact = insert(:user)

      {:ok, pid} = UserSession.start_link(user.id)
      UserSession.login(pid, self())
      :timer.sleep(100)
      flush_user_info()

      %{pid: pid, user: user, contact: contact}
    end

    test "get_contacts returns serialized contacts", %{pid: pid, user: user, contact: contact} do
      # First add a contact
      insert(:contact, %{user_id: user.id, contact_id: contact.id, nickname: "buddy"})

      UserSession.get_contacts(pid)

      assert_receive {:send, payload}
      assert payload.type == "contacts"
      assert is_list(payload.contacts)

      # Verify contact serialization
      if length(payload.contacts) > 0 do
        first_contact = List.first(payload.contacts)
        assert first_contact.id == contact.id
        assert first_contact.contact_info.nickname == "buddy"
      end
    end

    test "get_person_info returns user info", %{pid: pid, contact: contact} do
      UserSession.get_person_info(pid, contact.id)

      assert_receive {:send, payload}
      assert payload.type == "person_info"
      assert payload.person_info.id == contact.id
    end

    test "search_people returns search results", %{pid: pid, user: user, contact: contact} do
      # Search by username fragment
      search_input = String.slice(contact.username, 0, 3)

      UserSession.search_people(pid, search_input)

      assert_receive {:send, payload}
      assert payload.type == "search_people_results"
      assert is_list(payload.search_people_results)
    end

    test "add_contact succeeds", %{pid: pid, contact: contact} do
      UserSession.add_contact(pid, contact.id)

      assert_receive {:send, payload}
      assert payload.type == "contact_addition"
      assert payload.status == "success"
      assert payload.data.contact.id == contact.id
    end

    test "add_contact fails when already contact", %{pid: pid, user: user, contact: contact} do
      # Add contact first
      insert(:contact, %{user_id: user.id, contact_id: contact.id})

      UserSession.add_contact(pid, contact.id)

      assert_receive {:send, payload}
      assert payload.type == "contact_addition"
      assert payload.status == "failure"
    end

    test "delete_contact succeeds", %{pid: pid, user: user, contact: contact} do
      # Add contact first
      insert(:contact, %{user_id: user.id, contact_id: contact.id})

      UserSession.delete_contact(pid, contact.id)

      assert_receive {:send, payload}
      assert payload.type == "contact_deletion"
      assert payload.status == "success"
      assert payload.data.user_id == contact.id
    end

    test "delete_contact fails when not a contact", %{pid: pid, contact: contact} do
      UserSession.delete_contact(pid, contact.id)

      assert_receive {:send, payload}
      assert payload.type == "contact_deletion"
      assert payload.status == "failure"
    end
  end

  describe "user profile operations" do
    setup do
      user = insert(:user, %{username: "original_username", name: "Original Name"})

      {:ok, pid} = UserSession.start_link(user.id)
      UserSession.login(pid, self())
      :timer.sleep(100)
      flush_user_info()

      %{pid: pid, user: user}
    end

    test "change_username succeeds with valid username", %{pid: pid, user: user} do
      new_username = "new_username_123"

      UserSession.change_username(pid, new_username)

      assert_receive {:send, payload}, 1000
      assert payload.type == "username_change_result"
      assert payload.status == :success
      assert payload.data.new_username == new_username

      # Verify database was updated
      updated_user = Echo.Users.User.get(user.id)
      assert updated_user.username == new_username
    end

    # test "change_username fails with invalid username", %{pid: pid} do
    #   # Too short username
    #   UserSession.change_username(pid, "a")

    #   assert_receive {:send, payload}, 1000
    #   assert payload.type == "username_change_result"
    #   assert payload.status == :failure
    #   assert payload.data.reason != nil
    # end

    # test "change_name succeeds", %{pid: pid, user: user} do
    #   new_name = "New Display Name"

    #   UserSession.change_name(pid, new_name)

    #   assert_receive {:send, payload}, 1000
    #   assert payload.type == "name_change_result"
    #   assert payload.status == :success
    #   assert payload.data.new_name == new_name

    #   updated_user = Echo.Users.User.get(user.id)
    #   assert updated_user.name == new_name
    # end

    # test "change_nickname succeeds", %{pid: pid, user: user} do
    #   contact = insert(:user)
    #   insert(:contact, %{user_id: user.id, contact_id: contact.id})
    #   new_nickname = "bestie"

    #   UserSession.change_nickname(pid, contact.id, new_nickname)

    #   assert_receive {:send, payload}
    #   assert payload.type == "nickname_change_result"
    #   assert payload.status == :success
    #   assert payload.data.contact_id == contact.id
    #   assert payload.data.new_nickname == new_nickname
    # end
  end

  describe "group operations" do
    setup do
      user = insert(:user)
      member1 = insert(:user)
      member2 = insert(:user)

      {:ok, pid} = UserSession.start_link(user.id)
      UserSession.login(pid, self())
      :timer.sleep(100)
      flush_user_info()

      %{pid: pid, user: user, member1: member1, member2: member2}
    end

    test "create_group creates group and notifies members", %{pid: pid, user: user, member1: member1, member2: member2} do
      # Start sessions for other members to receive notifications
      {:ok, pid1} = UserSession.start_link(member1.id)
      UserSession.login(pid1, self())
      :timer.sleep(100)
      flush_user_info()
      {:ok, pid2} = UserSession.start_link(member2.id)
      UserSession.login(pid2, self())
      :timer.sleep(100)
      flush_user_info()
      group_payload = %{
        name: "Test Group",
        description: "A test group",
        avatar_url: nil,
        member_ids: [member1.id, member2.id]
      }

      UserSession.create_group(pid, group_payload)

      # Creator receives full chat info
      assert_receive {:send, creator_payload}
      assert creator_payload.type == "group_chat_created"
      assert creator_payload.chat.name == "Test Group"
      assert creator_payload.chat_item.name == "Test Group"

      # Members receive chat items (might be in any order)
      assert_receive {:send, member_payload1}
      assert member_payload1.type == "group_chat_created"
      assert member_payload1.chat_item.name == "Test Group"

      assert_receive {:send, member_payload2}
      assert member_payload2.type == "group_chat_created"
      assert member_payload2.chat_item.name == "Test Group"
    end

    test "change_group_name forwards to chat session", %{pid: pid, user: user} do
      group = insert(:chat, %{type: "group", creator_id: user.id, name: "Old Name"})
      insert(:chat_member, %{chat_id: group.id, user_id: user.id, role: "admin"})

      UserSession.change_group_name(pid, group.id, "New Group Name")

      :timer.sleep(100)
      updated_chat = Echo.Chats.Chat.get(group.id)
      assert updated_chat.name == "New Group Name"
    end

    test "change_group_description forwards to chat session", %{pid: pid, user: user} do
      group = insert(:chat, %{type: "group", creator_id: user.id, description: "Old description"})
      insert(:chat_member, %{chat_id: group.id, user_id: user.id, role: "admin"})

      UserSession.change_group_description(pid, group.id, "New description")

      :timer.sleep(100)
      updated_chat = Echo.Chats.Chat.get(group.id)
      assert updated_chat.description == "New description"
    end

    test "give_admin forwards to chat session", %{pid: pid, user: user, member1: member1} do
      group = insert(:chat, %{type: "group", creator_id: user.id})
      insert(:chat_member, %{chat_id: group.id, user_id: user.id, role: "admin"})
      insert(:chat_member, %{chat_id: group.id, user_id: member1.id, role: "member"})

      UserSession.give_admin(pid, group.id, member1.id)

      :timer.sleep(100)
      # Verify member is now admin
      member_role = Echo.ChatMembers.ChatMembers.get_role(group.id, member1.id)
      assert member_role == "admin"
    end
  end

  describe "private chat creation" do
    setup do
      user = insert(:user)
      receiver = insert(:user)

      {:ok, pid} = UserSession.start_link(user.id)
      UserSession.login(pid, self())
      :timer.sleep(100)
      flush_user_info()
      # Start receiver session
      {:ok, receiver_pid} = UserSession.start_link(receiver.id)
      UserSession.login(receiver_pid, self())
      :timer.sleep(100)
      flush_user_info()
      %{pid: pid, user: user, receiver: receiver, receiver_pid: receiver_pid}
    end

    test "create_private_chat creates chat and notifies both users", %{pid: pid, receiver: receiver, receiver_pid: receiver_pid} do
      UserSession.create_private_chat(pid, receiver.id)

      # Creator receives full chat info
      assert_receive {:send, creator_payload}
      assert creator_payload.type == "private_chat_created"
      assert creator_payload.chat.type == "private"
      assert creator_payload.chat_item.type == "private"

      # Receiver receives chat item
      assert_receive {:send, receiver_payload}
      assert receiver_payload.type == "private_chat_created"
      assert receiver_payload.chat_item.type == "private"
    end

    test "create_private_chat with self creates chat but only notifies once", %{pid: pid, user: user} do
      UserSession.create_private_chat(pid, user.id)

      # Should receive only one message (self-chat)
      assert_receive {:send, payload}
      assert payload.type == "private_chat_created"

      # No second message
      refute_receive {:send, _}
    end
  end

  describe "mark pending messages delivered" do
    setup do
      user = insert(:user)
      sender = insert(:user)

      # Start sender session
      {:ok, sender_pid} = UserSession.start_link(sender.id)
      UserSession.login(sender_pid, self())
      :timer.sleep(100)
      flush_user_info()
      {:ok, pid} = UserSession.start_link(user.id)
      # Don't attach socket for user (they're offline)

      %{pid: pid, user: user, sender: sender, sender_pid: sender_pid}
    end
  end

  describe "UserSession lifecycle" do
    setup do
      user = insert(:user)

      {:ok, pid} = UserSession.start_link(user.id)

      %{pid: pid, user: user}
    end

    test "starts with no socket attached", %{pid: pid} do
      refute UserSession.socket_alive?(pid)
    end

    test "attach_socket links and marks socket as alive", %{pid: pid} do
      UserSession.login(pid, self())
      :timer.sleep(100)
      flush_user_info()
      assert UserSession.socket_alive?(pid)
    end

    test "logout stops the session process", %{pid: pid} do
      ref = Process.monitor(pid)

      assert :ok = UserSession.logout(pid)

      assert_receive {:DOWN, ^ref, :process, ^pid, :normal}
    end
  end

  describe "socket message forwarding" do
    setup do
      user = insert(:user)
      {:ok, pid} = UserSession.start_link(user.id)

      # attach fake socket
      UserSession.login(pid, self())
      :timer.sleep(100)
      flush_user_info()
      %{pid: pid, user: user}
    end

    test "new_message forwards payload to socket", %{pid: pid} do
      msg = insert(:message)

      UserSession.new_message(pid, msg)

      assert_receive {:send, ^msg}
    end

    test "messages_delivered forwards ids to socket", %{pid: pid} do
      UserSession.messages_delivered(pid, [1, 2, 3])

      assert_receive {:send, payload}

      assert payload.type == "messages_delivered"
      assert payload.message_ids == [1, 2, 3]
    end

    test "send_payload forwards arbitrary payload", %{pid: pid} do
      payload = %{type: "custom_event", data: %{a: 1}}

      UserSession.send_payload(pid, payload)

      assert_receive {:send, ^payload}
    end
  end

  describe "socket disconnection handling" do
    setup do
      user = insert(:user)
      {:ok, pid} = UserSession.start_link(user.id)

      UserSession.login(pid, self())
      :timer.sleep(100)
      flush_user_info()
      %{pid: pid}
    end

    test "EXIT from socket clears socket and schedules timeout", %{pid: pid} do
      ref = Process.monitor(pid)

      send(pid, {:EXIT, self(), :normal})

      assert_receive {:DOWN, ^ref, :process, ^pid, _reason}, 100

      refute Process.alive?(pid)
    end

    test "process terminates after disconnect timeout", %{pid: pid} do
      send(pid, {:EXIT, self(), :normal})

      ref = Process.monitor(pid)

      # Wait slightly longer than session timeout
      :timer.sleep(Constants.session_timeout() + 50)

      assert_receive {:DOWN, ^ref, :process, ^pid, reason}, 1000
      assert reason in [:normal, :noproc]
    end
  end

  describe "when socket is nil" do
    setup do
      user = insert(:user)
      {:ok, pid} = UserSession.start_link(user.id)

      %{pid: pid}
    end

    test "new_message does nothing if socket is nil", %{pid: pid} do
      msg = insert(:message)

      UserSession.new_message(pid, msg)

      refute_receive {:send, _}
    end

    test "messages_delivered does nothing if socket is nil", %{pid: pid} do
      UserSession.messages_delivered(pid, [1, 2, 3])

      refute_receive {:send, _}
    end
  end

  defp flush_user_info do
    receive do
      {:send, %{type: "user_info"}} -> :ok
    after
      0 -> :ok
    end
  end
end
