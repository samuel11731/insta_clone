defmodule InstaClone.Accounts.Follower do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "followers" do
    belongs_to :follower, InstaClone.Accounts.User
    belongs_to :followed, InstaClone.Accounts.User

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(follower, attrs) do
    follower
    |> cast(attrs, [:follower_id, :followed_id])
    |> validate_required([:follower_id, :followed_id])
    |> unique_constraint([:follower_id, :followed_id])
  end
end
