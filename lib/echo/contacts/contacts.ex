defmodule Echo.Contacts.Contacts do
  import Ecto.Query
  alias Echo.Schemas.Contact
  alias Echo.Repo

  def list_contacts_for_user(user_id) do
    from(c in Contact,
      where: c.user_id == ^user_id,
      preload: [:contact]
    )
    |> Repo.all()
  end

  def get_contact_between(owner_user_id, contact_id) do
    from(c in Contact,
      where:
        c.user_id == ^owner_user_id and
        c.contact_id == ^contact_id,
      preload: [:contact]
    )
    |> Repo.one()
  end

  def get_contacts_map(user_id) do
    from(c in Contact,
      where: c.user_id == ^user_id,
      select: {
        c.contact_id,
        c.nickname
      }
    )
    |> Repo.all()
    |> Map.new()
  end

  def add_contact(owner_user_id, contact_user_id) do
    Contact.add_contact_changeset(
      owner_user_id,
      contact_user_id,
      nil
    )
    |> Repo.insert()
    |> case do
      {:ok, _contact} ->
        {:ok, get_contact_between(owner_user_id, contact_user_id)}

      {:error, changeset} ->
        {:error, format_changeset_error(changeset)}
    end
  end


  defp format_changeset_error(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, _opts} -> msg end)
    |> Enum.map(fn {field, [error | _]} ->
      {field, error}
    end)
    |> Map.new()
  end

  def delete_contact(owner_user_id, contact_user_id) do
    with true <- not is_nil(owner_user_id) or {:error, %{user_id: "can't be blank"}},
        true <- not is_nil(contact_user_id) or {:error, %{contact_id: "can't be blank"}},
        %Contact{} = contact <-
          Repo.get_by(Contact,
            user_id: owner_user_id,
            contact_id: contact_user_id
          ) || {:error, "not_found"},
        {:ok, _} <- Repo.delete(contact)
    do
      :ok
    else
      {:error, _} = err -> err
    end
  end




end
