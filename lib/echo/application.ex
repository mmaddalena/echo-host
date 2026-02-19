defmodule Echo.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    port =
      System.get_env("PORT", "4000")
      |> String.to_integer()

    dispatch =
      :cowboy_router.compile([
        {:_,
         [
           {"/ws", Echo.WS.UserSocket, []},
           {:_, Plug.Cowboy.Handler, {Echo.Http.Router, []}}
         ]}
      ])

    children = [
      {Goth, name: Echo.Goth},
      Echo.Repo,
      Echo.ProcessRegistry,
      Echo.Users.UserSessionSup,
      Echo.Chats.ChatSessionSup,
      %{
        id: :http_listener,
        start: {
          :cowboy,
          :start_clear,
          [
            :http_listener,
            [port: port],
            %{env: %{dispatch: dispatch}}
          ]
        }
      }
    ]

    opts = [strategy: :one_for_one, name: Echo.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
