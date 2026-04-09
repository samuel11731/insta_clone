defmodule InstaCloneWeb.TimelineLive.Notifications do
  use InstaCloneWeb, :live_view

  alias InstaClone.Timeline

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Timeline.subscribe_notifications(socket.assigns.current_scope.user.id)
    end

    notifications = Timeline.list_notifications(socket.assigns.current_scope.user.id)

    # Mark all as read when opening the page
    Timeline.mark_notifications_as_read(socket.assigns.current_scope.user.id)

    {:ok, assign(socket, notifications: notifications, page_title: "Notifications")}
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
