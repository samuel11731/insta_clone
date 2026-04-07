defmodule InstaClone.Chat.Message do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "messages" do
    field :content, :string
    field :media_url, :string
    field :media_type, :string, default: "text"
    field :media_duration, :integer

    belongs_to :conversation, InstaClone.Chat.Conversation
    belongs_to :user, InstaClone.Accounts.User

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(message, attrs) do
    message
    |> cast(attrs, [:content, :conversation_id, :user_id, :media_url, :media_type, :media_duration])
    |> validate_required([:conversation_id, :user_id])
  end
end
