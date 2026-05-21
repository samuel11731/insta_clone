defmodule InstaCloneWeb.MessagesLive.Index do
  use InstaCloneWeb, :live_view

  alias InstaClone.Chat
  alias InstaClone.Accounts

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(
        InstaClone.PubSub,
        "user_chat:#{socket.assigns.current_scope.user.id}"
      )

      # Global presence for online indicators
      Phoenix.PubSub.subscribe(InstaClone.PubSub, "global_presence")
    end

    conversations = Chat.list_user_conversations(socket.assigns.current_scope.user.id)

    # Initialize online users from Presence
    online_users =
      if connected?(socket) do
        InstaCloneWeb.Presence.list("global_presence") |> Map.keys() |> MapSet.new()
      else
        MapSet.new()
      end

    {:ok,
     socket
     |> assign(:conversations, conversations)
     |> assign(:active_conversation, nil)
     |> assign(:messages, [])
     |> assign(:search_query, "")
     |> assign(:search_results, [])
     |> assign(:message_form, to_form(%{"content" => ""}))
     |> assign(:is_recording, false)
     |> assign(:recording_duration, 0)
     |> assign(:audio_preview_ready, false)
     |> assign(:voice_note_duration, 0)
     |> assign(:online_users, online_users)
     |> assign(:typing_user_ids, MapSet.new())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    case params["user_id"] do
      nil ->
        {:noreply, socket}

      user_id ->
        # start-conversation logic
        {:ok, conversation} =
          Chat.get_or_create_conversation(socket.assigns.current_scope.user.id, user_id)

        conversations = Chat.list_user_conversations(socket.assigns.current_scope.user.id)
        if connected?(socket), do: Chat.subscribe(conversation.id)

        # Stop typing indicator for previous conversation if any
        if old_conv = socket.assigns.active_conversation do
          Phoenix.PubSub.broadcast(
            InstaClone.PubSub,
            "chat:#{old_conv.id}",
            {:typing_stop, socket.assigns.current_scope.user.id}
          )
        end

        # Mark as read
        Chat.mark_messages_as_read(conversation.id, socket.assigns.current_scope.user.id)

        {:noreply,
         socket
         |> assign(:conversations, conversations)
         |> assign(:active_conversation, conversation)
         |> assign(:messages, Chat.list_messages(conversation.id))
         |> assign(:typing_user_ids, MapSet.new())}
    end
  end

  @impl true
  def handle_event("search-users", %{"q" => query}, socket) do
    results = if String.trim(query) == "", do: [], else: Accounts.search_users(query)
    {:noreply, assign(socket, search_query: query, search_results: results)}
  end

  def handle_event("start-conversation", %{"user-id" => user2_id}, socket) do
    {:ok, conversation} =
      Chat.get_or_create_conversation(socket.assigns.current_scope.user.id, user2_id)

    # Refresh conversations
    conversations = Chat.list_user_conversations(socket.assigns.current_scope.user.id)

    # Subscribe to specific conversation to get its live feed
    if connected?(socket), do: Chat.subscribe(conversation.id)

    {:noreply,
     socket
     |> assign(:conversations, conversations)
     |> assign(:active_conversation, conversation)
     |> assign(:messages, Chat.list_messages(conversation.id))
     |> assign(:search_query, "")
     |> assign(:search_results, [])}
  end

  def handle_event("select-conversation", %{"id" => id}, socket) do
    conversation = Chat.get_conversation!(id)
    if connected?(socket), do: Chat.subscribe(conversation.id)

    # Stop typing indicator for previous conversation if any
    if old_conv = socket.assigns.active_conversation do
      Phoenix.PubSub.broadcast(
        InstaClone.PubSub,
        "chat:#{old_conv.id}",
        {:typing_stop, socket.assigns.current_scope.user.id}
      )
    end

    # Mark as read
    Chat.mark_messages_as_read(conversation.id, socket.assigns.current_scope.user.id)

    {:noreply,
     socket
     |> assign(:active_conversation, conversation)
     |> assign(:messages, Chat.list_messages(conversation.id))
     |> assign(:typing_user_ids, MapSet.new())}
  end

  def handle_event("close-conversation", _params, socket) do
    if conv = socket.assigns.active_conversation do
      Phoenix.PubSub.broadcast(
        InstaClone.PubSub,
        "chat:#{conv.id}",
        {:typing_stop, socket.assigns.current_scope.user.id}
      )
    end

    {:noreply,
     socket
     |> assign(:active_conversation, nil)
     |> assign(:messages, [])}
  end

  def handle_event("send-message", %{"content" => content}, socket) do
    if content != "" and socket.assigns.active_conversation do
      Chat.create_message(%{
        content: content,
        conversation_id: socket.assigns.active_conversation.id,
        user_id: socket.assigns.current_scope.user.id
      })

      # Also broadcast to the recipient so their inbox list updates
      other_user =
        if socket.assigns.active_conversation.user1_id == socket.assigns.current_scope.user.id do
          socket.assigns.active_conversation.user2
        else
          socket.assigns.active_conversation.user1
        end

      Phoenix.PubSub.broadcast(
        InstaClone.PubSub,
        "user_chat:#{other_user.id}",
        {:conversation_updated, socket.assigns.active_conversation.id}
      )
    end

    {:noreply, assign(socket, message_form: to_form(%{"content" => ""}))}
  end

  def handle_event("typing_start", _params, socket) do
    if conv = socket.assigns.active_conversation do
      Phoenix.PubSub.broadcast(
        InstaClone.PubSub,
        "chat:#{conv.id}",
        {:typing_start, socket.assigns.current_scope.user.id}
      )
    end

    {:noreply, socket}
  end

  def handle_event("typing_stop", _params, socket) do
    if conv = socket.assigns.active_conversation do
      Phoenix.PubSub.broadcast(
        InstaClone.PubSub,
        "chat:#{conv.id}",
        {:typing_stop, socket.assigns.current_scope.user.id}
      )
    end

    {:noreply, socket}
  end

  def handle_event("mic-clicked", _params, socket) do
    IO.puts("MIC BUTTON CLICKED (phx-click)")
    {:noreply, socket}
  end

  def handle_event("debug", %{"msg" => msg}, socket) do
    IO.puts("DEBUG FROM JS: #{msg}")
    {:noreply, socket}
  end

  def handle_event("cancel-upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :audio, ref)}
  end

  def handle_event("recording-started", _params, socket) do
    {:noreply,
     assign(socket, is_recording: true, recording_duration: 0, audio_preview_ready: false)}
  end

  def handle_event("recording-tick", %{"seconds" => seconds}, socket) do
    {:noreply, assign(socket, recording_duration: seconds)}
  end

  def handle_event("audio-preview-ready", %{"duration" => duration}, socket) do
    {:noreply,
     assign(socket, is_recording: false, audio_preview_ready: true, voice_note_duration: duration)}
  end

  def handle_event("cancel-audio", _params, socket) do
    {:noreply, assign(socket, audio_preview_ready: false, voice_note_duration: 0)}
  end

  def handle_event("send-audio-url", %{"url" => url, "duration" => duration}, socket) do
    if socket.assigns.active_conversation do
      Chat.create_message(%{
        media_url: url,
        media_type: "audio",
        media_duration: duration,
        conversation_id: socket.assigns.active_conversation.id,
        user_id: socket.assigns.current_scope.user.id
      })
    end

    {:noreply, assign(socket, audio_preview_ready: false, voice_note_duration: 0)}
  end

  def handle_event("audio-too-short", _params, socket) do
    {:noreply,
     socket
     |> assign(is_recording: false, audio_preview_ready: false)
     |> put_flash(:error, "Voice note too short")}
  end

  @impl true
  def handle_info({:new_message, message}, socket) do
    cond do
      socket.assigns.active_conversation &&
          socket.assigns.active_conversation.id == message.conversation_id ->
        # It's for the currently open conversation
        messages = socket.assigns.messages ++ [message]

        # Auto mark as read if it's from the other user
        if message.user_id != socket.assigns.current_scope.user.id do
          Chat.mark_messages_as_read(
            socket.assigns.active_conversation.id,
            socket.assigns.current_scope.user.id
          )
        end

        # Pull conversation to top of list
        conversations = Chat.list_user_conversations(socket.assigns.current_scope.user.id)

        {:noreply, assign(socket, messages: messages, conversations: conversations)}

      true ->
        conversations = Chat.list_user_conversations(socket.assigns.current_scope.user.id)
        {:noreply, assign(socket, conversations: conversations)}
    end
  end

  @impl true
  def handle_info(:messages_read, socket) do
    # When messages are read, we need to refresh the messages to show "Seen" status
    messages =
      if conv = socket.assigns.active_conversation do
        Chat.list_messages(conv.id)
      else
        socket.assigns.messages
      end

    {:noreply, assign(socket, messages: messages)}
  end

  @impl true
  def handle_info({:typing_start, user_id}, socket) do
    if user_id != socket.assigns.current_scope.user.id do
      {:noreply,
       socket
       |> assign(typing_user_ids: MapSet.put(socket.assigns.typing_user_ids, user_id))
       |> push_event("scroll_to_bottom", %{id: "chat-thread"})}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_info({:typing_stop, user_id}, socket) do
    {:noreply,
     socket
     |> assign(typing_user_ids: MapSet.delete(socket.assigns.typing_user_ids, user_id))
     |> push_event("scroll_to_bottom", %{id: "chat-thread"})}
  end

  @impl true
  def handle_info(%{event: "presence_diff", payload: %{joins: joins, leaves: leaves}}, socket) do
    online_users =
      socket.assigns.online_users
      |> MapSet.union(MapSet.new(Map.keys(joins)))
      |> MapSet.difference(MapSet.new(Map.keys(leaves)))

    {:noreply, assign(socket, online_users: online_users)}
  end

  def handle_info({:conversation_updated, _id}, socket) do
    conversations = Chat.list_user_conversations(socket.assigns.current_scope.user.id)
    {:noreply, assign(socket, conversations: conversations)}
  end

  @impl true
  def handle_info(:notifications_read, socket) do
    {:noreply, assign(socket, :unread_notifications_count, 0)}
  end
end
