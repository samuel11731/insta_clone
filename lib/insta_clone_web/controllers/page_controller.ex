defmodule InstaCloneWeb.PageController do
  use InstaCloneWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
