defmodule Echo.DataCase do
  @moduledoc """
  This module defines the setup for tests requiring
  access to the application's data layer.

  You may define functions here to be used as helpers in
  your tests.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      alias Echo.Repo

      import Ecto
      import Ecto.Changeset
      import Ecto.Query
      import Echo.DataCase
    end
  end

  setup tags do
    Echo.DataCase.setup_sandbox(tags)
    :ok
  end

  @doc """
  Sets up the SQL sandbox based on the test tags.
  """
  def setup_sandbox(tags) do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Echo.Repo)

    if not tags[:async] do
      Ecto.Adapters.SQL.Sandbox.mode(Echo.Repo, {:shared, self()})
    end
  end

  @doc """
  A helper to transform changeset errors into a map of messages.

      assert {:error, changeset} = User.create(%{password: "short"})
      assert "should be at least 8 character(s)" in errors_on(changeset).password
  """
  def errors_on(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {message, opts} ->
      Regex.replace(~r"%{(\w+)}", message, fn _, key ->
        opts
        |> Keyword.get(String.to_existing_atom(key), key)
        |> to_string()
      end)
    end)
  end
end
