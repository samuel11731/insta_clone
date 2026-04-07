defmodule InstaClone.Timeline.Story do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "stories" do
    field :media_path, :string
    # "image" or "video"
    field :media_type, :string
    field :expires_at, :utc_datetime
    belongs_to :user, InstaClone.Accounts.User

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(story, attrs, user_scope) do
    story
    |> cast(attrs, [:media_path, :media_type, :expires_at])
    |> put_change(:user_id, user_scope.user.id)
    |> set_expires_at()
    |> validate_required([:media_path, :media_type, :user_id, :expires_at])
    |> validate_inclusion(:media_type, ["image", "video"])
  end

  defp set_expires_at(changeset) do
    if get_field(changeset, :expires_at) do
      changeset
    else
      expires_at = DateTime.utc_now() |> DateTime.add(24, :hour) |> DateTime.truncate(:second)
      put_change(changeset, :expires_at, expires_at)
    end
  end
end
