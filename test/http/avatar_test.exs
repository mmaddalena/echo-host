defmodule Echo.Http.AvatarTest do
  use Echo.ConnCase, async: true

  setup do
    user = insert(:user, %{})
    {:ok, token} = Echo.Auth.JWT.generate_token(user.id)
    {:ok, user: user, token: token}
  end

  describe "POST /api/users/me/avatar" do
    # test "uploads avatar successfully", %{token: token} do
    #   boundary = "----WebKitFormBoundary7MA4YWxkTrZu0gW"
    #   file_content = File.read!("test/support/avatar.svg")

    #   body = create_multipart_body(%{
    #     "avatar" => {"avatar.svg", file_content, "image/svg+xml"}
    #   }, boundary)

    #   conn = request("POST", "/api/users/me/avatar", body, [
    #     {"authorization", "Bearer #{token}"},
    #     {"content-type", "multipart/form-data; boundary=#{boundary}"}
    #   ])

    #   response = json_response(conn, 200)
    #   assert response["avatar_url"] =~ "/uploads/avatars/"
    # end

    test "returns 400 with invalid file type", %{token: token} do
      boundary = "----WebKitFormBoundary7MA4YWxkTrZu0gW"

      body = create_multipart_body(%{
        "avatar" => {"test.txt", "This is not an image", "text/plain"}
      }, boundary)

      conn = request("POST", "/api/users/me/avatar", body, [
        {"authorization", "Bearer #{token}"},
        {"content-type", "multipart/form-data; boundary=#{boundary}"}
      ])

      response = json_response(conn, 400)
      assert response["error"] == "Avatar upload failed"
    end

    test "returns 400 without token" do
      boundary = "----WebKitFormBoundary7MA4YWxkTrZu0gW"

      body = create_multipart_body(%{
        "avatar" => {"avatar.svg", "fakecontent", "image/svg+xml"}
      }, boundary)

      conn = request("POST", "/api/users/me/avatar", body, [
        {"content-type", "multipart/form-data; boundary=#{boundary}"}
      ])

      response = json_response(conn, 400)
      assert response["error"] == "Avatar upload failed"
    end
  end

  # describe "POST /api/groups/:id/avatar" do
  #   test "uploads group avatar successfully", %{token: token, user: user} do
  #     group = insert(:chat, %{creator_id: user.id, type: "group"})

  #     boundary = "----WebKitFormBoundary7MA4YWxkTrZu0gW"
  #     file_content = File.read!("test/support/avatar.svg")

  #     body = create_multipart_body(%{
  #       "avatar" => {"avatar.svg", file_content, "image/svg+xml"}
  #     }, boundary)

  #     conn = request("POST", "/api/groups/#{group.id}/avatar", body, [
  #       {"authorization", "Bearer #{token}"},
  #       {"content-type", "multipart/form-data; boundary=#{boundary}"}
  #     ])

  #     response = json_response(conn, 200)
  #     assert response["avatar_url"] =~ "/uploads/group_avatars/"
  #   end
  # end

  # Helper function to create proper multipart bodies with file uploads
  defp create_multipart_body(fields, boundary) when is_map(fields) do
    parts = Enum.map(fields, fn {name, {filename, content, content_type}} ->
      [
        "--", boundary, "\r\n",
        "Content-Disposition: form-data; name=\"", name, "\"; filename=\"", filename, "\"\r\n",
        "Content-Type: ", content_type, "\r\n",
        "\r\n",
        content, "\r\n"
      ]
    end)

    (parts ++ ["--", boundary, "--\r\n"])
    |> List.flatten()
    |> IO.iodata_to_binary()
  end
end
