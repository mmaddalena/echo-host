defmodule Echo.Http.AuthTest do
  use Echo.ConnCase, async: true

  describe "POST /api/login" do
    test "returns token with valid credentials" do
      user = insert(:user, %{username: "testuser", password: "12345678"})

      conn = request("POST", "/api/login", Jason.encode!(%{
        username: user.username,
        password: "12345678"
      }), [{"content-type", "application/json"}])

      response = json_response(conn, 200)
      assert %{"token" => token} = response
      assert {:ok, user.id} == Echo.Auth.JWT.extract_user_id(token)
    end

    test "returns 401 with invalid password" do
      user = insert(:user, %{username: "testuser", password: "12345678"})

      conn = request("POST", "/api/login", Jason.encode!(%{
        username: user.username,
        password: "wrongpass"
      }), [{"content-type", "application/json"}])

      response = json_response(conn, 401)
      assert response["error"] == "Invalid password"
    end

    test "returns 401 with non-existent user" do
      conn = request("POST", "/api/login", Jason.encode!(%{
        username: "nonexistent",
        password: "12345678"
      }), [{"content-type", "application/json"}])

      response = json_response(conn, 401)
      assert response["error"] == "User not found"
    end
  end

  describe "POST /api/register" do
    test "creates user and returns token" do
      params = %{
        "username" => "newuser",
        "password" => "12345678",
        "name" => "New User",
        "email" => "example@gmail.com"
      }

      # Create multipart body with proper CRLF line endings
      boundary = "----WebKitFormBoundary7MA4YWxkTrZu0gW"
      body = create_multipart_body(params, boundary)

      conn = request("POST", "/api/register", body, [
        {"content-type", "multipart/form-data; boundary=#{boundary}"}
      ])

      response = json_response(conn, 201)
      assert %{"token" => token} = response

      # Verify user was created
      user = Echo.Repo.get_by(Echo.Schemas.User, username: "newuser")
      assert user.name == "New User"
    end

    # test "returns 409 when username taken" do
    #   existing = insert(:user, %{username: "takenuser", password: "12345678"})

    #   params = %{
    #     "username" => existing.username,
    #     "password" => "12345678",
    #     "name" => "New User",
    #     "email" => "example@gmail.com"
    #   }

    #   boundary = "----WebKitFormBoundary7MA4YWxkTrZu0gW"
    #   body = create_multipart_body(params, boundary)

    #   conn = request("POST", "/api/register", body, [
    #     {"content-type", "multipart/form-data; boundary=#{boundary}"}
    #   ])

    #   response = json_response(conn, 409)
    #   assert response["error"] == "Username already taken"
    # end
  end

  defp create_multipart_body(params, boundary) do
    parts = Enum.map(params, fn {key, value} ->
      [
        "--", boundary, "\r\n",
        "Content-Disposition: form-data; name=\"", key, "\"\r\n",
        "\r\n",
        to_string(value), "\r\n"
      ]
    end)

    # Add final boundary and convert to binary
    (parts ++ ["--", boundary, "--\r\n"])
    |> List.flatten()
    |> IO.iodata_to_binary()
  end
end
