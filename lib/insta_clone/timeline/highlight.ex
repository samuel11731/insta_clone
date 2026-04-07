defmodule InstaClone.Timeline.Highlight do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "highlights" do
    field :title, :string
    field :cover_path, :string
    belongs_to :user, InstaClone.Accounts.User

    many_to_many :stories, InstaClone.Timeline.Story,
      join_through: "highlight_stories",
      on_replace: :delete

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(highlight, attrs) do
    highlight
    |> cast(attrs, [:title, :cover_path, :user_id])
    |> validate_required([:title, :user_id])
  end
end
