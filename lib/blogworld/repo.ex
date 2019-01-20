defmodule Blogworld.Repo do
  use Ecto.Repo,
    otp_app: :blogworld,
    adapter: Ecto.Adapters.Postgres
end
