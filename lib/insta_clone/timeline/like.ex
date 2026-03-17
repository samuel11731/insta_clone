defmodule InstaClone.Timeline.Like do
  use Ecto.Schema
  import Ecto.Changeset
  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "likes" do
    belongs_to :user, InstaClone.Accounts.User
    belongs_to :post, InstaClone.Timeline.Post
    timestamps()
  end
  @doc false
  def changeset(like, attrs) do
    like
    |> cast(attrs, [:user_id, :post_id])
    |> validate_required([:user_id, :post_id])
    |> unique_constraint([:user_id, :post_id])
  end
end
