defmodule Echo.Schemas.BlockedContact do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  schema "blocked_contacts" do
    timestamps(type: :utc_datetime)

    belongs_to :blocker, Echo.Schemas.User,
      foreign_key: :blocker_id,
      type: :binary_id,
      primary_key: true  # Part of composite primary key

    belongs_to :blocked, Echo.Schemas.User,
      foreign_key: :blocked_id,
      type: :binary_id,
      primary_key: true  # Part of composite primary key
  end

  def changeset(blocked_contact, attrs) do
    blocked_contact
    |> cast(attrs, [:blocker_id, :blocked_id])
    |> validate_required([:blocker_id, :blocked_id])
    |> unique_constraint([:blocker_id, :blocked_id],
      name: :blocked_contacts_pkey,  # Matches primary key constraint name
      message: "Already blocked"
    )
    |> check_constraint(:blocker_id,
      name: :cannot_block_self,
      message: "Cannot block yourself"
    )
    |> foreign_key_constraint(:blocker_id,
      name: :blocked_contacts_blocker_id_fkey
    )
    |> foreign_key_constraint(:blocked_id,
      name: :blocked_contacts_blocked_id_fkey
    )
    |> validate_not_blocking_self()
  end

  defp validate_not_blocking_self(changeset) do
    blocker_id = get_field(changeset, :blocker_id)
    blocked_id = get_field(changeset, :blocked_id)

    if blocker_id && blocked_id && blocker_id == blocked_id do
      add_error(changeset, :blocked_id, "Cannot block yourself")
    else
      changeset
    end
  end
end
