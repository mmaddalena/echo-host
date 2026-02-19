ExUnit.start()
Code.require_file("support/data_case.ex", __DIR__)
Code.require_file("support/conn_case.ex", __DIR__)
Code.require_file("support/factory.ex", __DIR__)

Ecto.Adapters.SQL.Sandbox.mode(Echo.Repo, :manual)
