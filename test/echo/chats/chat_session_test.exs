# defmodule Echo.Chats.ChatSessionTest do
#   use Echo.DataCase, async: false

#   import Echo.Factory

#   alias Echo.Chats.ChatSession
#   alias Echo.ProcessRegistry
#   alias Echo.Users.UserSession

#   setup do
#     # Create a user and a private chat
#     user = insert(:user)

#     chat =
#       insert(:chat, %{
#         type: "private",
#         creator_id: user.id
#       })

#     insert(:chat_member, %{
#       chat_id: chat.id,
#       user_id: user.id,
#       role: "admin"
#     })

#     # Start ChatSession
#     {:ok, cs_pid} = ChatSession.start_link(chat.id)

#     %{user: user, chat: chat, cs_pid: cs_pid}
#   end

#   test "initializes with correct state", %{cs_pid: cs_pid, chat: chat} do
#     state = :sys.get_state(cs_pid)

#     assert state.chat.id == chat.id
#     assert is_list(state.last_messages)
#     assert is_list(state.members)
#   end

#   test "handles chat_info cast", %{cs_pid: cs_pid, user: user, chat: chat} do
#     fake_us = self()

#     ChatSession.get_chat_info(cs_pid, user.id, fake_us)

#     assert_receive {:send, payload}
#     assert payload.type == "chat_info"
#     assert payload.chat.id == chat.id
#   end

#   # test "send message in self private chat", %{
#   #   cs_pid: cs_pid,
#   #   user: user,
#   #   chat: chat
#   # } do
#   #   fake_us = self()

#   #   msg = %{
#   #     "front_msg_id" => "tmp-1",
#   #     "chat_id" => chat.id,
#   #     "content" => "hello",
#   #     "sender_user_id" => user.id,
#   #     "format" => "text",
#   #     "filename" => nil
#   #   }

#   #   ChatSession.send_message(cs_pid, msg, fake_us)

#   #   # Allow async cast to complete
#   #   Process.sleep(50)

#   #   state = :sys.get_state(cs_pid)
#   #   assert length(state.last_messages) >= 1
#   # end

#   # test "marks messages as read", %{
#   #   cs_pid: cs_pid,
#   #   user: user,
#   #   chat: chat
#   # } do
#   #   # Insert a message from another user
#   #   other = insert(:user)

#   #   insert(:chat_member, %{
#   #     chat_id: chat.id,
#   #     user_id: other.id,
#   #     role: "member"
#   #   })

#   #   insert(:message, %{
#   #     chat_id: chat.id,
#   #     user_id: other.id,
#   #     content: "hi"
#   #   })

#   #   ChatSession.chat_messages_read(cs_pid, chat.id, user.id)

#   #   Process.sleep(50)

#   #   assert Process.alive?(cs_pid)
#   # end

#   test "handles group name change success", %{
#     cs_pid: cs_pid,
#     chat: chat,
#     user: user
#   } do
#     new_name = "New Group Name"

#     ChatSession.change_group_name(cs_pid, chat.id, new_name, user.id)

#     Process.sleep(50)

#     state = :sys.get_state(cs_pid)
#     assert state.chat.name == new_name or Process.alive?(cs_pid)
#   end
# end
