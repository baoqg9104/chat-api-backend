defmodule ChatApiWeb.UserController do
  use ChatApiWeb, :controller
  use PhoenixSwagger

  alias ChatApi.Accounts
  alias ChatApi.Accounts.User

  action_fallback ChatApiWeb.FallbackController

  swagger_path :index do
    get("/api/users")
    summary("Get the list of users")
    description("Returns a list of all users in the system")
    tag("Users")
    response(200, "Success")
  end

  def index(conn, _params) do
    users = Accounts.list_users()
    render(conn, :index, users: users)
  end

  swagger_path :create do
    post("/api/users")
    summary("Create a new user")
    description("Create and save new user information into the system")
    tag("Users")
    parameter(:user, :body, Schema.ref(:UserParams), "User information", required: true)
    response(201, "Successfully created", Schema.ref(:User))
    response(422, "Invalid data")
  end

  def create(conn, %{"user" => user_params}) do
    with {:ok, %User{} = user} <- Accounts.create_user(user_params) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", ~p"/api/users/#{user}")
      |> render(:show, user: user)
    end
  end

  # swagger_path :show do
  #   get("/api/users/{id}")
  #   summary("View user details")
  #   description("Returns detailed information of a user based on their ID")
  #   tag("Users")
  #   parameter(:id, :path, :string, "User ID", required: true)
  #   response(200, "Success", Schema.ref(:User))
  #   response(404, "User not found")
  # end

  # def show(conn, %{"id" => id}) do
  #   user = Accounts.get_user!(id)
  #   render(conn, :show, user: user)
  # end

  swagger_path :me do
    get("/api/users/me")
    summary("View current user details")
    description("Returns detailed information of the currently authenticated user")
    tag("Users")
    response(200, "Success", Schema.ref(:User))
  end

  def me(conn, _params) do
    user = Guardian.Plug.current_resource(conn)
    render(conn, :show, user: user)
  end

  swagger_path :update do
    put("/api/users/{id}")
    summary("Update user information")
    description("Updates the information of a user based on their ID")
    tag("Users")
    parameter(:id, :path, :string, "User ID", required: true)

    parameter(:user, :body, Schema.ref(:UserUpdateParams), "User information to be updated",
      required: true
    )

    response(200, "Successfully updated", Schema.ref(:User))
    response(404, "User not found")
    response(422, "Invalid data")
  end

  def update(conn, %{"id" => id, "user" => user_params}) do
    user = Accounts.get_user!(id)

    with {:ok, %User{} = user} <- Accounts.update_user(user, user_params) do
      render(conn, :show, user: user)
    end
  end

  swagger_path :delete do
    PhoenixSwagger.Path.delete("/api/users/{id}")
    summary("Delete a user")
    description("Deletes a user from the system based on their ID")
    tag("Users")
    parameter(:id, :path, :string, "User ID", required: true)
    response(204, "Successfully deleted")
    response(404, "User not found")
  end

  def delete(conn, %{"id" => id}) do
    user = Accounts.get_user!(id)

    with {:ok, %User{}} <- Accounts.delete_user(user) do
      send_resp(conn, :no_content, "")
    end
  end

  swagger_path :authenticate do
    post("/api/users/authenticate")
    summary("Authenticate a user")
    description("Authenticates a user with email and password")
    tag("Users")
    parameter(:email, :query, :string, "Email", required: true)
    parameter(:password, :query, :string, "Password", required: true)
    response(200, "Authenticated successfully", Schema.ref(:User))
    response(401, "Unauthorized")
  end

  def authenticate(conn, %{"email" => email, "password" => password}) do
    with {:ok, user} <- Accounts.authenticate_user(email, password),
         {:ok, token, _claims} <- ChatApi.Auth.Guardian.encode_and_sign(user) do
      json(conn, %{token: token})
    else
      _ ->
        conn
        |> put_status(:unauthorized)
        |> json(%{error: "Invalid credentials"})
    end
  end

  def swagger_definitions do
    %{
      User:
        swagger_schema do
          title("User")
          description("User information")

          properties do
            id(:integer, "User ID")
            username(:string, "The user's username")
            email(:string, "The user's email address", format: :email)
            status(:string, "The user's status", enum: ["active", "inactive"])
            inserted_at(:string, "Creation time", format: :datetime)
            updated_at(:string, "Last update time", format: :datetime)
          end

          example(%{
            data: %{
              id: 1,
              username: "johndoe",
              email: "john.doe@example.com",
              status: "active",
              inserted_at: "2023-01-01T12:00:00Z",
              updated_at: "2023-01-01T12:00:00Z"
            }
          })
        end,
      UserParams:
        swagger_schema do
          title("UserParams")
          description("Parameters for creating a new user")

          properties do
            username(:string, "The user's username", required: true)
            email(:string, "The user's email address", format: :email, required: true)
            password(:string, "The user's password", required: true, minLength: 6)
            status(:string, "Account status (e.g., active, inactive)", required: true)
          end

          example(%{
            user: %{
              username: "johndoe",
              email: "john.doe@example.com",
              password: "secretpassword",
              status: "active"
            }
          })
        end,
      UserUpdateParams:
        swagger_schema do
          title("UserUpdateParams")
          description("Parameters for updating a user")

          properties do
            username(:string, "The user's username", required: true)
            # email(:string, "The user's email address", format: :email, required: true)
            # password(:string, "The user's password", required: true, minLength: 6)
            status(:string, "Account status (e.g., active, inactive)", required: true)
          end

          example(%{
            user: %{
              username: "johndoe",
              # email: "john.doe@example.com",
              # password: "secretpassword",
              status: "active"
            }
          })
        end
    }
  end
end
