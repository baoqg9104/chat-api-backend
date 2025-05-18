defmodule ChatApiWeb.Router do
  use ChatApiWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
    plug CORSPlug, origin: ["*"]
  end

  pipeline :auth do
    plug Guardian.Plug.Pipeline,
      module: ChatApi.Auth.Guardian,
      error_handler: ChatApi.Auth.ErrorHandler

    plug Guardian.Plug.VerifyHeader
    # plug Guardian.Plug.EnsureAuthenticated
    plug Guardian.Plug.LoadResource
  end

  scope "/api", ChatApiWeb do
    pipe_through :api

    post "/users/authenticate", UserController, :authenticate
    post "/users", UserController, :create
  end

  scope "/api", ChatApiWeb do
    pipe_through [:api, :auth]

    resources "/users", UserController, except: [:new, :edit, :create]
    get "/users/me", UserController, :me
    resources "/messages", MessageController, except: [:new, :edit]
    get "/messages/user/:user_id", MessageController, :user_messages

  end

  scope "/api/swagger" do
    forward "/", PhoenixSwagger.Plug.SwaggerUI, otp_app: :chat_api, swagger_file: "swagger.json"
  end

  def swagger_info do
    %{
      info: %{
        version: "1.0",
        title: "My App"
      },
      securityDefinitions: %{
        Bearer: %{
          type: "apiKey",
          name: "authorization",
          in: "header",
          description: "Enter 'Bearer <token>'"
        }
      },
      security: [%{"Bearer" => []}]
    }
  end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:chat_api, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through [:fetch_session, :protect_from_forgery]

      live_dashboard "/dashboard", metrics: ChatApiWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
