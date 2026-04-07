defmodule InstaCloneWeb.StaticFallbackController do
  use InstaCloneWeb, :controller

  def not_found(conn, _params) do
    conn
    |> put_status(:not_found)
    |> text("Not Found")
    |> halt()
  end
end
