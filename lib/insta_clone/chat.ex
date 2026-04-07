defmodule InstaClone.Chat do
  import Ecto.Query, warn: false
  alias InstaClone.Repo

  alias InstaClone.Chat.Conversation
  alias InstaClone.Chat.Message

  # --- Conversations ---

  def get_or_create_conversation(user1_id, user2_id) do
    # Ensure a consistent ordering to prevent duplicating conversations
    [u1, u2] = Enum.sort([user1_id, user2_id])

    query =
      from c in Conversation,
        where: c.user1_id == ^u1 and c.user2_id == ^u2,
        preload: [:user1, :user2]

    case Repo.one(query) do
      nil ->
        case %Conversation{}
             |> Conversation.changeset(%{user1_id: u1, user2_id: u2})
             |> Repo.insert() do
          {:ok, conv} -> {:ok, Repo.preload(conv, [:user1, :user2])}
          error -> error
        end

      conversation ->
        {:ok, conversation}
    end
  end

  def list_user_conversations(user_id) do
    # Only return conversations that have at least one message
    Conversation
    |> join(:inner, [c], m in Message, on: m.conversation_id == c.id)
    |> where([c], c.user1_id == ^user_id or c.user2_id == ^user_id)
    |> group_by([c], c.id)
    |> order_by([c], desc: c.updated_at)
    |> preload([:user1, :user2])
    |> Repo.all()
    |> Enum.map(fn conversation ->
      # Preload the last message manually for now to keep it simple and efficient
      last_message =
        Message
        |> where([m], m.conversation_id == ^conversation.id)
        |> order_by([m], desc: m.inserted_at)
        |> limit(1)
        |> Repo.one()

      Map.put(conversation, :last_message, last_message)
    end)
  end

  def get_conversation!(id) do
    Repo.get!(Conversation, id)
    |> Repo.preload([:user1, :user2])
  end

  # --- Messages ---

  def list_messages(conversation_id) do
    query =
      from m in Message,
        where: m.conversation_id == ^conversation_id,
        order_by: [asc: m.inserted_at],
        preload: [:user]

    Repo.all(query)
  end

  def create_message(attrs \\ %{}) do
    %Message{}
    |> Message.changeset(attrs)
    |> Repo.insert()
    |> case do
      {:ok, msg} ->
        msg = Repo.preload(msg, :user)
        broadcast({:ok, msg}, msg.conversation_id)
        touch_conversation(msg.conversation_id)
        {:ok, msg}

      error ->
        error
    end
  end

  defp touch_conversation(conversation_id) do
    from(c in Conversation, where: c.id == ^conversation_id)
    |> Repo.update_all(set: [updated_at: DateTime.truncate(DateTime.utc_now(), :second)])
  end

  # --- PubSub ---

  def subscribe(conversation_id) do
    Phoenix.PubSub.subscribe(InstaClone.PubSub, "chat:#{conversation_id}")
  end

  defp broadcast({:ok, message}, conversation_id) do
    Phoenix.PubSub.broadcast(
      InstaClone.PubSub,
      "chat:#{conversation_id}",
      {:new_message, message}
    )

    {:ok, message}
  end
end
