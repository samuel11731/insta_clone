defmodule InstaCloneWeb.Router do
  use InstaCloneWeb, :router

  import InstaCloneWeb.UserAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {InstaCloneWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_scope_for_user
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", InstaCloneWeb do
    pipe_through [:browser, :redirect_if_user_is_authenticated]

    get "/", PageController, :home
  end

  scope "/", InstaCloneWeb do
    pipe_through [:browser]

    get "/welcome", PageController, :home
  end

  # Catch-all for missing static image files that Plug.Static passes through
  scope "/images", InstaCloneWeb do
    get "/*path", StaticFallbackController, :not_found
  end

  if Application.compile_env(:insta_clone, :dev_routes) do
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: InstaCloneWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  scope "/", InstaCloneWeb do
    pipe_through [:browser, :require_authenticated_user]

    live_session :require_authenticated_user,
      on_mount: [{InstaCloneWeb.UserAuth, :require_authenticated}] do
      live "/users/settings", UserLive.Settings, :edit
      live "/users/settings/confirm-email/:token", UserLive.Settings, :confirm_email
      live "/timeline", TimelineLive.Index, :index
      live "/explore", TimelineLive.Explore, :index
      live "/messages", TimelineLive.Messages, :index
      live "/notifications", TimelineLive.Notifications, :index
      live "/profile", TimelineLive.Profile, :index
      live "/profile/:username", TimelineLive.Profile, :index
    end

    post "/users/update-password", UserSessionController, :update_password
    post "/uploads/audio", AudioController, :upload
  end

  scope "/", InstaCloneWeb do
    pipe_through [:browser]

    live_session :current_user,
      on_mount: [{InstaCloneWeb.UserAuth, :mount_current_scope}] do
      live "/users/register", UserLive.Registration, :new
      live "/users/log-in", UserLive.Login, :new
      live "/users/log-in/:token", UserLive.Confirmation, :new
    end

    post "/users/log-in", UserSessionController, :create
    delete "/users/log-out", UserSessionController, :delete
  end

  scope "/", InstaCloneWeb do
    pipe_through [:browser, :require_authenticated_user]

    live_session :username_profile,
      on_mount: [{InstaCloneWeb.UserAuth, :require_authenticated}] do
      live "/:username", TimelineLive.Profile, :index
    end
  end
end
