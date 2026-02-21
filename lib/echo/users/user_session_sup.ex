defmodule Echo.Users.UserSessionSup do
  alias Echo.ProcessRegistry
  use DynamicSupervisor

  def start_link(_arg) do
    DynamicSupervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  @impl true
  def init(:ok) do
    DynamicSupervisor.init(
      strategy: :one_for_one
    )
  end

  def get_or_start(user_id) do
    case ProcessRegistry.whereis_user_session(user_id) do
      nil ->
        start_session(user_id)

      pid ->
        if Process.alive?(pid) do
          {:ok, pid}
        else
          start_session(user_id)
        end
    end
  end


  defp start_session(user_id) do

    spec = %{
      id: {Echo.Users.UserSession, user_id},
      start: {Echo.Users.UserSession, :start_link, [user_id]},
      restart: :temporary
    }

    case DynamicSupervisor.start_child(__MODULE__, spec) do
      {:ok, pid} ->
        IO.puts("Started UserSession for user_id #{user_id} with pid #{inspect(pid)}")
        {:ok, pid}

      {:error, {:already_started, pid}} ->
        {:ok, pid}

      {:error, reason} ->
        {:error, reason}
    end
  end

  def is_session_alive?(user_id) do
    case ProcessRegistry.whereis_user_session(user_id) do
      nil -> false
      _pid -> true
    end
  end
end
