defmodule Echo.Schemas.Contact do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "contacts" do
    field :nickname, :string
    timestamps(type: :utc_datetime)

    belongs_to :user, Echo.Schemas.User
    belongs_to :contact, Echo.Schemas.User, foreign_key: :contact_id


  end

  def changeset(contact, attrs) do
    contact
    |> cast(attrs, [:nickname, :user_id, :contact_id])
    |> validate_required([:user_id, :contact_id])
    |> validate_length(:nickname, min: 1, max: 50)
    |> unique_constraint([:user_id, :contact_id], name: :contacts_user_id_contact_id_index)
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:contact_id)
  end

  def add_contact_changeset(user_id, contact_id, nickname) do
    %__MODULE__{}
    |> changeset(%{
      user_id: user_id,
      contact_id: contact_id,
      nickname: nickname
    })
  end
end
