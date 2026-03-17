defmodule InstaClone.Timeline.Post do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "posts" do
    field :caption, :string
    field :image_path, :string
    belongs_to :user, InstaClone.Accounts.User
    has_many :likes, InstaClone.Timeline.Like
    has_many :comments, InstaClone.Timeline.Comment

    timestamps(type: :utc_datetime)
  end

  @spec changeset(
          {map(),
           %{
             optional(atom()) =>
               atom()
               | {:array | :assoc | :embed | :in | :map | :parameterized | :supertype | :try,
                  any()}
           }}
          | %{
              :__struct__ => atom() | %{:__changeset__ => any(), optional(any()) => any()},
              optional(atom()) => any()
            },
          :invalid | %{optional(:__struct__) => none(), optional(atom() | binary()) => any()},
          any()
        ) :: Ecto.Changeset.t()
  @doc false
  def changeset(post, attrs, user_scope) do
    post
    |> cast(attrs, [:caption, :image_path])
    |> put_change(:user_id, user_scope.user.id)
    |> validate_required([:image_path, :user_id])
  end
end
