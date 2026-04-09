defmodule InstaClone.Timeline.Notification do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "notifications" do
    # "like", "comment", "follow"
    field :type, :string
    field :is_read, :boolean, default: false

    belongs_to :actor, InstaClone.Accounts.User
    belongs_to :recipient, InstaClone.Accounts.User
    belongs_to :post, InstaClone.Timeline.Post

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(notification, attrs) do
    notification
    |> cast(attrs, [:type, :is_read, :actor_id, :recipient_id, :post_id])
    |> validate_required([:type, :actor_id, :recipient_id])
  end
end
