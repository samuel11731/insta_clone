defmodule InstaCloneWeb.TimelineLive.Profile do
  use InstaCloneWeb, :live_view

  alias InstaClone.Accounts

  @impl true
  def mount(params, _session, socket) do
    current_user = socket.assigns.current_scope.user

    profile_user =
      if params["username"] do
        Accounts.get_user_by_username!(params["username"])
      else
        current_user
      end

    posts = InstaClone.Timeline.list_user_posts(socket.assigns.current_scope, profile_user.id)
    post_count = InstaClone.Timeline.count_user_posts(profile_user)

    follower_count = Accounts.count_followers(profile_user)
    following_count = Accounts.count_following(profile_user)

    is_own_profile = current_user.id == profile_user.id

    is_following =
      if is_own_profile do
        false
      else
        Accounts.following?(current_user, profile_user)
      end

    socket =
      socket
      |> assign(:current_user, current_user)
      |> assign(:user, profile_user)
      |> assign(:posts, posts)
      |> assign(:post_count, post_count)
      |> assign(:follower_count, follower_count)
      |> assign(:following_count, following_count)
      |> assign(:is_following, is_following)
      |> assign(:is_own_profile, is_own_profile)

    {:ok, socket}
  end

  @impl true
  def handle_params(_params, _url, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("follow", _params, socket) do
    current_user_id = socket.assigns.current_user.id
    profile_user_id = socket.assigns.user.id

    case Accounts.follow_user(current_user_id, profile_user_id) do
      {:ok, _follower} ->
        {:noreply,
         socket
         |> assign(:is_following, true)
         |> assign(:follower_count, socket.assigns.follower_count + 1)}

      {:error, _changeset} ->
        {:noreply, socket}
    end
  end

  @impl true
  def handle_event("unfollow", _params, socket) do
    current_user_id = socket.assigns.current_user.id
    profile_user_id = socket.assigns.user.id

    Accounts.unfollow_user(current_user_id, profile_user_id)

    {:noreply,
     socket
     |> assign(:is_following, false)
     |> assign(:follower_count, socket.assigns.follower_count - 1)}
  end
end
