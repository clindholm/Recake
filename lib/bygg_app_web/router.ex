defmodule ByggAppWeb.Router do
  use ByggAppWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", ByggAppWeb do
    pipe_through :browser

    get "/", PageController, :index
  end

  scope "/", ByggAppWeb do
    pipe_through [:browser]

    get "/users/login", UserSessionController, :new
  end

  # Other scopes may use custom stacks.
  # scope "/api", ByggAppWeb do
  #   pipe_through :api
  # end
end
