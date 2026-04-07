defmodule InstaClone.Chat.Conversation do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "conversations" do
    belongs_to :user1, InstaClone.Accounts.User
    belongs_to :user2, InstaClone.Accounts.User

    has_many :messages, InstaClone.Chat.Message

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(conversation, attrs) do
    conversation
    |> cast(attrs, [:user1_id, :user2_id])
    |> validate_required([:user1_id, :user2_id])
    |> unique_constraint([:user1_id, :user2_id])
  end
end
