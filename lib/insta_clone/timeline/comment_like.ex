defmodule InstaClone.Timeline.CommentLike do
  use Ecto.Schema
  import Ecto.Changeset
  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "comment_likes" do
    belongs_to :user, InstaClone.Accounts.User
    belongs_to :comment, InstaClone.Timeline.Comment
    timestamps(type: :utc_datetime)
  end
  def changeset(comment_like, attrs) do
    comment_like
    |> cast(attrs, [:user_id, :comment_id])
    |> validate_required([:user_id, :comment_id])
    |> unique_constraint([:user_id, :comment_id])
  end
end
