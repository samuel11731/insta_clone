defmodule InstaCloneWeb.TimelineLive.Notifications do
  use InstaCloneWeb, :live_view

  alias InstaClone.Timeline
  alias InstaClone.Accounts

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Timeline.subscribe_notifications(socket.assigns.current_scope.user.id)
    end

    current_user = socket.assigns.current_scope.user
    notifications = Timeline.list_notifications(current_user.id)

    # Build a set of actor IDs that current_user already follows
    # (only relevant for follow notifications)
    followed_ids =
      notifications
      |> Enum.filter(&(&1.type in ["follow", "follow_back"]))
      |> Enum.map(& &1.actor_id)
      |> Enum.filter(&Accounts.following?(current_user.id, &1))
      |> MapSet.new()

    # Mark all as read when opening the page
    Timeline.mark_notifications_as_read(current_user.id)

    {:ok,
     assign(socket,
       notifications: notifications,
       followed_ids: followed_ids,
       page_title: "Notifications"
     )}
  end

  @impl true
  def handle_event("follow_back", %{"user-id" => actor_id}, socket) do
    current_user = socket.assigns.current_scope.user

    case Accounts.follow_user(current_user.id, actor_id) do
      {:ok, _} ->
        {:noreply,
         assign(socket, followed_ids: MapSet.put(socket.assigns.followed_ids, actor_id))}

      {:error, _} ->
        {:noreply, socket}
    end
  end

  @impl true
  def handle_info({:new_notification, notification}, socket) do
    {:noreply, assign(socket, notifications: [notification | socket.assigns.notifications])}
  end

  @impl true
  def handle_info(:notifications_read, socket) do
    # Just refresh if another tab marked them as read
    {:noreply,
     assign(socket,
       notifications: Timeline.list_notifications(socket.assigns.current_scope.user.id)
     )}
  end

  @impl true
  def handle_info({:notification_deleted, notification_id}, socket) do
    notifications = Enum.reject(socket.assigns.notifications, &(&1.id == notification_id))
    {:noreply, assign(socket, notifications: notifications)}
  end
end
