defmodule InstaCloneWeb.Presence do
  use Phoenix.Presence,
    otp_app: :insta_clone,
    pubsub_server: InstaClone.PubSub
end
