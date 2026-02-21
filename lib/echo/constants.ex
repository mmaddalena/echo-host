defmodule Echo.Constants do
  @online "Online"
  @offline "Offline"

  @outgoing "outgoing"
  @incoming "incoming"

  @private "private"
  @group "group"

  @state_sent "sent"
  @state_delivered "delivered"
  @state_read "read"

  def online, do: @online
  def offline, do: @offline

  def outgoing, do: @outgoing
  def incoming, do: @incoming

  def private_chat(), do: @private
  def group_chat(), do: @group

  def state_sent(), do: @state_sent
  def state_delivered(), do: @state_delivered
  def state_read(), do: @state_read

  def messages_page_size, do: 50

  def max_search_results(), do: 50

  def session_timeout(), do: 500

  def idle_timeout(), do: 1000 * 60 * 10
end
