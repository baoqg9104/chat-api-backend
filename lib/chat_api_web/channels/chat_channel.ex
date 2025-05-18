# lib/chat_api_web/channels/chat_channel.ex
defmodule ChatApiWeb.ChatChannel do
  use ChatApiWeb, :channel

  def join("chat:" <> _room_id, _params, socket) do
    {:ok, socket}
  end

  def handle_in(
        "new_message",
        %{
          "message" => %{
            "content" => content,
            "sender_id" => sender_id,
            "receiver_id" => receiver_id,
            "tempId" => tempId
          }
        },
        socket
      )
      when is_binary(content) and is_binary(sender_id) and is_binary(receiver_id) and
             is_binary(tempId) do
    attrs = %{
      content: content,
      sender_id: sender_id,
      receiver_id: receiver_id,
      status: "sent"
    }

    case ChatApi.Chats.create_message(attrs) do
      {:ok, message} ->
        broadcast_payload = %{
          id: message.id,
          content: message.content,
          senderId: message.sender_id,
          receiverId: message.receiver_id,
          timestamp: message.inserted_at,
          tempId: tempId,
          status: message.status
        }

        broadcast(socket, "new_message", broadcast_payload)
        {:reply, {:ok, broadcast_payload}, socket}

      {:error, _reason} ->
        {:reply, {:error, "Failed to save message"}, socket}
    end
  end

  def handle_in("new_message", _payload, socket) do
    {:reply, {:error, %{reason: "Invalid message format"}}, socket}
  end
end
