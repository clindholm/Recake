defmodule ByggAppWeb.Router do
  use ByggAppWeb, :router

  import ByggAppWeb.UserAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_user
  end

  pipeline :minimal_layout do
    plug :put_layout, {ByggAppWeb.LayoutView, :minimal}
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", ByggAppWeb do
    pipe_through :browser

    get "/", PageController, :index
  end

  # Other scopes may use custom stacks.
  # scope "/api", ByggAppWeb do
  #   pipe_through :api
  # end

  scope "/", ByggAppWeb do
    pipe_through [:browser, :minimal_layout, :redirect_if_user_is_authenticated]

    get "/users/register", UserRegistrationController, :new
    post "/users/register", UserRegistrationController, :create
    get "/users/login", UserSessionController, :new
    post "/users/login", UserSessionController, :create
    get "/users/reset_password", UserResetPasswordController, :new
    post "/users/reset_password", UserResetPasswordController, :create
    get "/users/reset_password/:token", UserResetPasswordController, :edit
    put "/users/reset_password/:token", UserResetPasswordController, :update
  end

  scope "/", ByggAppWeb do
    pipe_through [:browser, :require_authenticated_user]

    delete "/users/logout", UserSessionController, :delete
    get "/users/settings", UserSettingsController, :edit
    put "/users/settings/update_password", UserSettingsController, :update_password
    put "/users/settings/update_email", UserSettingsController, :update_email
    get "/users/settings/confirm_email/:token", UserSettingsController, :confirm_email

    get "/jobs", JobController, :index
    get "/jobs/new", JobController, :new
    post "/jobs/new", JobController, :create

    get "/requests", JobRequestController, :index
  end

  scope "/", ByggAppWeb do
    pipe_through [:browser]

    get "/users/confirm", UserConfirmationController, :new
    post "/users/confirm", UserConfirmationController, :create
    get "/users/confirm/:token", UserConfirmationController, :confirm
  end

  if Mix.env() in [:dev, :test] do
    import Phoenix.LiveDashboard.Router

    scope "/" do
      pipe_through :browser
      live_dashboard "/dashboard", metrics: ScrapWeb.Telemetry
    end
  end
end
