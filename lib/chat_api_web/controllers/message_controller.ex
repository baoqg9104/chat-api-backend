defmodule ChatApiWeb.MessageController do
  use ChatApiWeb, :controller
  use PhoenixSwagger

  alias ChatApi.Chats
  alias ChatApi.Chats.Message

  action_fallback ChatApiWeb.FallbackController

  swagger_path :index do
    get("/api/messages")
    summary("Get the list of messages")
    description("Returns a list of all messages in the system")
    tag("Messages")
    response(200, "Success")
  end

  def index(conn, _params) do
    messages = Chats.list_messages()
    render(conn, :index, messages: messages)
  end

  swagger_path :create do
    post("/api/messages")
    summary("Create a new message")
    description("Create and save new message information into the system")
    tag("Messages")
    parameter(:message, :body, Schema.ref(:MessageParams), "Message information", required: true)
    response(201, "Successfully created", Schema.ref(:Message))
    response(422, "Invalid data")
  end

  def create(conn, %{"message" => message_params}) do
    message_params = Map.put_new(message_params, "status", "sent")

    with {:ok, %Message{} = message} <- Chats.create_message(message_params) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", ~p"/api/messages/#{message}")
      |> render(:show, message: message)
    end
  end

  swagger_path :show do
    get("/api/messages/{id}")
    summary("View message details")
    description("Returns detailed information of a message based on its ID")
    tag("Messages")
    parameter(:id, :path, :string, "Message ID", required: true)
    response(200, "Success", Schema.ref(:Message))
    response(404, "Message not found")
  end

  def show(conn, %{"id" => id}) do
    message = Chats.get_message!(id)
    render(conn, :show, message: message)
  end

  swagger_path :update do
    put("/api/messages/{id}")
    summary("Update message information")
    description("Updates the information of a message based on its ID")
    tag("Messages")
    parameter(:id, :path, :string, "Message ID", required: true)

    parameter(:message, :body, Schema.ref(:MessageUpdateParams), "Updated message information",
      required: true
    )

    response(200, "Successfully updated", Schema.ref(:Message))
    response(422, "Invalid data")
  end

  def update(conn, %{"id" => id, "message" => message_params}) do
    message = Chats.get_message!(id)

    with {:ok, %Message{} = message} <- Chats.update_message(message, message_params) do
      render(conn, :show, message: message)
    end
  end

  swagger_path :delete do
    PhoenixSwagger.Path.delete("/api/messages/{id}")
    summary("Delete a message")
    description("Deletes a message based on its ID")
    tag("Messages")
    parameter(:id, :path, :string, "Message ID", required: true)
    response(204, "No content")
    response(404, "Message not found")
  end

  def delete(conn, %{"id" => id}) do
    message = Chats.get_message!(id)

    with {:ok, %Message{}} <- Chats.delete_message(message) do
      send_resp(conn, :no_content, "")
    end
  end

  swagger_path :user_messages do
    get("/api/messages/user/{user_id}")
    summary("Get messages between two users")
    description("Returns a list of messages exchanged between two users")
    tag("Messages")
    parameter(:user_id, :path, :string, "User ID", required: true)
    response(200, "Success", Schema.ref(:Message))
  end

  def user_messages(conn, %{"user_id" => other_user_id}) do
    with ["Bearer " <> token] <- get_req_header(conn, "authorization"),
         {:ok, claims} <- ChatApi.Auth.Guardian.decode_and_verify(token),
         {:ok, current_user} <- ChatApi.Auth.Guardian.resource_from_claims(claims) do
      messages = Chats.list_messages_between_users(current_user.id, other_user_id)
      render(conn, :index, messages: messages)
    else
      _ ->
        conn
        |> put_status(:unauthorized)
        |> json(%{error: "Invalid or missing token"})
    end
  end

  def swagger_definitions do
    %{
      Message:
        swagger_schema do
          title("Message")
          description("A message in the chat system")

          properties do
            id(:integer, "ID of the message", required: true)
            content(:string, "Content of the message", required: true)
            sender_id(:string, "ID of the sender", required: true)
            receiver_id(:string, "ID of the receiver", required: true)
            timestamp(:string, "Timestamp of when the message was sent", format: :date_time)
          end

          example(%{
            message: %{
              id: 1,
              content: "Hello!",
              sender_id: "123",
              receiver_id: "456",
              timestamp: "2023-10-01T12:00:00Z"
            }
          })
        end,
      MessageParams:
        swagger_schema do
          title("MessageParams")
          description("Parameters for creating or updating a message")

          properties do
            content(:string, "Content of the message", required: true)
            sender_id(:string, "ID of the sender", required: true)
            receiver_id(:string, "ID of the receiver", required: true)
          end

          example(%{
            message: %{
              sender_id: "123",
              receiver_id: "456",
              content: "Hello!"
            }
          })
        end,
      MessageUpdateParams:
        swagger_schema do
          title("MessageUpdateParams")
          description("Parameters for updating a message")

          properties do
            content(:string, "Content of the message", required: false)
            status(:string, "Status of the message (e.g., sent, read)", required: false)
          end

          example(%{
            message: %{
              content: "Updated content",
              status: "read"
            }
          })
        end
    }
  end
end
