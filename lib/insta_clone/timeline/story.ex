defmodule InstaClone.Timeline.Story do
  use Ecto.Schema
  import Ecto.Changeset

  schema "stories" do
    field :media_path, :string
    field :media_type, :string # "image" or "video"
    field :expires_at, :utc_datetime
    belongs_to :user, InstaClone.Accounts.User

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(story, attrs) do
    story
    |> cast(attrs, [:media_path, :media_type, :expires_at, :user_id])
    |> validate_required([:media_path, :media_type, :expires_at, :user_id])
    |> validate_inclusion(:media_type, ["image", "video"])
  end
end
