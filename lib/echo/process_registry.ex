defmodule Echo.ProcessRegistry do
  @moduledoc """
  Registry global para procesos de dominio:
  - {:user, user_id} -> UserSession pid
  - {:chat, chat_id} -> ChatSession pid

  Uses Elixir's built-in Registry which automatically cleans up dead processes.
  """

  def start_link do
    Registry.start_link(keys: :unique, name: __MODULE__)
  end

  def child_spec(_opts) do
    Registry.child_spec(
      keys: :unique,
      name: __MODULE__
    )
  end

  @doc """
  Registers the current process with a user ID.
  """
  def register_user_session(user_id) when is_binary(user_id) do
    Registry.register(__MODULE__, {:user, user_id}, [])
  end

  @doc """
  Registers the current process with a chat ID.
  """
  def register_chat_session(chat_id) when is_binary(chat_id) do
    Registry.register(__MODULE__, {:chat, chat_id}, [])
  end

  @doc """
  Looks up a user session by user ID.
  """
  def whereis_user_session(user_id) when is_binary(user_id) do
    case Registry.lookup(__MODULE__, {:user, user_id}) do
      [{pid, _}] -> pid
      [] -> nil
    end
  end

  @doc """
  Looks up a chat session by chat ID.
  """
  def whereis_chat_session(chat_id) when is_binary(chat_id) do
    case Registry.lookup(__MODULE__, {:chat, chat_id}) do
      [{pid, _}] -> pid
      [] -> nil
    end
  end

  @doc """
  Gets all registered user sessions.
  """
  def list_user_sessions do
    __MODULE__
    |> Registry.select([
      {{:"$1", :"$2", :"$3"}, [{:==, {:element, 1, :"$1"}, :user}], [{{:"$1", :"$2"}}]}
    ])
    |> Enum.map(fn {{:user, user_id}, pid} -> {user_id, pid} end)
  end

  @doc """
  Gets all registered chat sessions.
  """
  def list_chat_sessions do
    __MODULE__
    |> Registry.select([
      {{:"$1", :"$2", :"$3"}, [{:==, {:element, 1, :"$1"}, :chat}], [{{:"$1", :"$2"}}]}
    ])
    |> Enum.map(fn {{:chat, chat_id}, pid} -> {chat_id, pid} end)
  end

  def unregister_user_session(user_id) do
    Registry.unregister(__MODULE__, {:user, user_id})
  end
end
