defmodule Echo.ConnCase do
  @moduledoc """
  This module defines the test case to be used by tests that require
  setting up a connection.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      # Import conveniences for testing with connections
      import Plug.Conn
      import Echo.ConnCase
      import Echo.Factory

      alias Echo.Repo
      alias Ecto.Adapters.SQL.Sandbox

      # Helper to make test requests
      def request(method, path, body \\ nil, headers \\ []) do
        conn = Plug.Test.conn(method, path, body || "")
        conn = Enum.reduce(headers, conn, fn {key, value}, acc ->
          Plug.Conn.put_req_header(acc, key, value)
        end)
        Echo.Http.Router.call(conn, [])
      end

      def json_response(conn, status) do
        assert conn.status == status
        assert get_resp_header(conn, "content-type") |> List.first() =~ "application/json"
        Jason.decode!(conn.resp_body)
      end

      def response(conn, status) do
        assert conn.status == status
        conn.resp_body
      end
    end
  end

  setup tags do
    # Setup sandbox for database tests
    pid = Ecto.Adapters.SQL.Sandbox.start_owner!(Echo.Repo, shared: not tags[:async])
    on_exit(fn -> Ecto.Adapters.SQL.Sandbox.stop_owner(pid) end)

    :ok
  end
end
