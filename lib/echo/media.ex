defmodule Echo.Media do
  alias Echo.Users.User
  alias Echo.Chats.Chat

  @bucket "echo-fiuba"
  @scope "https://www.googleapis.com/auth/devstorage.full_control"

  def upload_user_avatar(user_id, %Plug.Upload{} = upload) do
    # upload to gcs
    with {:ok, url} <- upload_avatar(user_id, upload),
         # update avatar_url in db
         {:ok, user} <- User.update_avatar(user_id, url) do
      {:ok, user}
    end
  end

  def upload_to_gcs(object_name, upload) do
    {:ok, %{token: token}} = Goth.fetch(Echo.Goth, @scope)

    conn = GoogleApi.Storage.V1.Connection.new(token)
    {:ok, object} =
      GoogleApi.Storage.V1.Api.Objects.storage_objects_insert_simple(
        conn,
        @bucket,
        "multipart",
        %GoogleApi.Storage.V1.Model.Object{
          name: object_name,
          contentType: upload.content_type
        },
        upload.path
      )

    {:ok, object}
  rescue
    e ->
      IO.inspect(e, label: "upload error")
      {:error, :upload_failed}
  end

  defp public_url(object_name) do
    "https://storage.googleapis.com/#{@bucket}/#{object_name}"
  end

  def upload_chat_file(user_id, %Plug.Upload{} = upload) do
    ext = Path.extname(upload.filename)

    object_name =
      "chat/#{user_id}/#{Ecto.UUID.generate()}#{ext}"

    with {:ok, object} <- upload_to_gcs(object_name, upload) do
      url = "https://storage.googleapis.com/#{@bucket}/#{object.name}"
      {:ok, url}
    end
  end

  def upload_register_avatar(%Plug.Upload{} = upload) do
    ext = Path.extname(upload.filename)

    object_name =
      "avatars/register/#{Ecto.UUID.generate()}#{ext}"

    with {:ok, object} <- upload_to_gcs(object_name, upload) do
      url = "https://storage.googleapis.com/#{@bucket}/#{object.name}"
      {:ok, url}
    end
  end

  def upload_avatar(user_id, %Plug.Upload{} = upload) do
    ext = Path.extname(upload.filename)

    object_name =
      "avatars/users/#{user_id}-#{Ecto.UUID.generate()}#{ext}"

    with {:ok, _object} <- upload_to_gcs(object_name, upload) do
      {:ok, public_url(object_name)}
    end
  rescue
    e ->
      IO.inspect(e, label: "Avatar upload error")
      {:error, :upload_failed}
  end

  def upload_group_avatar(group_id, %Plug.Upload{} = upload) do
    ext = Path.extname(upload.filename)

    object_name =
      "avatars/groups/#{group_id}-#{Ecto.UUID.generate()}#{ext}"

    with {:ok, object} <- upload_to_gcs(object_name, upload) do
        Chat.update_group_avatar(group_id, public_url(object.name))
        {:ok, public_url(object.name)}
    end

    rescue
      e ->
        IO.inspect(e, label: "Group avatar upload error")
        {:error, :upload_failed}
    end
end
