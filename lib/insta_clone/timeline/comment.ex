defmodule InstaClone.Timeline.Comment do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "comments" do
    field :body, :string

    belongs_to :user, InstaClone.Accounts.User
    belongs_to :post, InstaClone.Timeline.Post
    has_many :likes, InstaClone.Timeline.CommentLike

    belongs_to :parent, InstaClone.Timeline.Comment
    has_many :replies, InstaClone.Timeline.Comment, foreign_key: :parent_id

    timestamps()
  end

  @doc false
  def changeset(comment, attrs) do
    comment
    |> cast(attrs, [:body, :user_id, :post_id, :parent_id])
    |> validate_required([:body, :user_id, :post_id])
  end
end
