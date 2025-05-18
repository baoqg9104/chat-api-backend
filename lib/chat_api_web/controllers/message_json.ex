defmodule ChatApiWeb.MessageJSON do
  alias ChatApi.Chats.Message

  @doc """
  Renders a list of messages.
  """
  def index(%{messages: messages}) do
    %{data: for(message <- messages, do: data(message))}
  end

  @doc """
  Renders a single message.
  """
  def show(%{message: message}) do
    %{data: data(message)}
  end

  defp data(%Message{} = message) do
    %{
      id: message.id,
      content: message.content,
      status: message.status,
      sender_id: message.sender_id,
      receiver_id: message.receiver_id,
      timestamp: message.inserted_at,
    }
  end
end
