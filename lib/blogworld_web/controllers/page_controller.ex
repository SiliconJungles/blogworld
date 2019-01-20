defmodule BlogworldWeb.PageController do
  use BlogworldWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
