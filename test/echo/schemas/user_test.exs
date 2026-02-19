defmodule Echo.Schemas.UserTest do
  use Echo.DataCase, async: true

  alias Echo.Schemas.User

  @valid_attrs %{
    username: "martin123",
    email: "martin@example.com",
    password: "securepass",
    name: "Martin"
  }

  # -----------------------------
  # login changeset
  # -----------------------------
  describe "changeset/2 (login)" do
    test "valid data" do
      changeset = User.changeset(%User{}, %{
        username: "user1",
        password: "password123"
      })

      assert changeset.valid?
    end

    test "missing username" do
      changeset = User.changeset(%User{}, %{password: "pass"})
      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).username
    end

    test "missing password" do
      changeset = User.changeset(%User{}, %{username: "user"})
      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).password
    end

    test "username too short" do
      changeset = User.changeset(%User{}, %{
        username: "ab",
        password: "password"
      })

      refute changeset.valid?
    end
  end

  # -----------------------------
  # registration changeset
  # -----------------------------
  describe "registration_changeset/2" do
    test "valid data creates password hash" do
      changeset = User.registration_changeset(%User{}, @valid_attrs)

      assert changeset.valid?
      assert get_change(changeset, :password_hash)
    end

    test "requires all fields" do
      changeset = User.registration_changeset(%User{}, %{})
      refute changeset.valid?

      errors = errors_on(changeset)

      assert :username in Map.keys(errors)
      assert :email in Map.keys(errors)
      assert :password in Map.keys(errors)
    end

    test "invalid email format" do
      attrs = Map.put(@valid_attrs, :email, "invalid")
      changeset = User.registration_changeset(%User{}, attrs)

      refute changeset.valid?
      assert :email in Map.keys(errors_on(changeset))
    end

    test "invalid username format" do
      attrs = Map.put(@valid_attrs, :username, "invalid username")
      changeset = User.registration_changeset(%User{}, attrs)

      refute changeset.valid?
      assert :username in Map.keys(errors_on(changeset))
    end

    test "password too short" do
      attrs = Map.put(@valid_attrs, :password, "123")
      changeset = User.registration_changeset(%User{}, attrs)

      refute changeset.valid?
      assert :password in Map.keys(errors_on(changeset))
    end

    test "sets default avatar when none provided" do
      changeset = User.registration_changeset(%User{}, @valid_attrs)

      avatar = get_change(changeset, :avatar_url)
      assert avatar != nil
      assert String.contains?(avatar, "storage.googleapis.com")
    end

    test "keeps provided avatar" do
      attrs =
        Map.put(
          @valid_attrs,
          :avatar_url,
          "https://example.com/avatar.png"
        )

      changeset = User.registration_changeset(%User{}, attrs)

      assert get_change(changeset, :avatar_url) ==
               "https://example.com/avatar.png"
    end
  end

  # -----------------------------
  # username changeset
  # -----------------------------
  describe "username_changeset/2" do
    test "valid username" do
      user = %User{}

      changeset =
        User.username_changeset(user, %{username: "new_user"})

      assert changeset.valid?
    end

    test "invalid username format" do
      user = %User{}

      changeset =
        User.username_changeset(user, %{username: "bad name"})

      refute changeset.valid?
    end
  end

  # -----------------------------
  # name changeset
  # -----------------------------
  describe "name_changeset/2" do
    test "valid name" do
      user = %User{}
      changeset = User.name_changeset(user, %{name: "Martin"})

      assert changeset.valid?
    end

    test "empty name is invalid" do
      user = %User{}
      changeset = User.name_changeset(user, %{name: ""})

      refute changeset.valid?
    end
  end
end
