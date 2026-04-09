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

    # Fetch highlights
    highlights = InstaClone.Timeline.list_user_highlights(profile_user.id)

    socket =
      socket
      |> assign(:current_user, current_user)
      |> assign(:user, profile_user)
      |> assign(:posts, posts)
      |> assign(:highlights, highlights)
      |> assign(:post_count, post_count)
      |> assign(:follower_count, follower_count)
      |> assign(:following_count, following_count)
      |> assign(:is_following, is_following)
      |> assign(:is_own_profile, is_own_profile)
      |> assign(:show_edit_modal, false)
      |> assign(:profile_form, to_form(Accounts.User.profile_changeset(profile_user, %{})))
      |> assign(:active_post_id, nil)
      |> assign(:active_post, nil)
      |> assign(:comments, [])
      |> assign(:reply_to_user, nil)
      |> assign(:expanded_replies, MapSet.new())
      |> assign(:open_comment_menu, nil)
      |> assign(:reply_to_comment_id, nil)
      |> allow_upload(:avatar, accept: ~w(.jpg .jpeg .png), max_entries: 1)

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

  def handle_event("validate-profile", %{"user" => user_params}, socket) do
    changeset =
      socket.assigns.user
      |> Accounts.User.profile_changeset(user_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, profile_form: to_form(changeset))}
  end

  def handle_event("open-edit-modal", _params, socket) do
    {:noreply, assign(socket, show_edit_modal: true)}
  end

  def handle_event("close-edit-modal", _params, socket) do
    {:noreply, assign(socket, show_edit_modal: false)}
  end

  def handle_event("save-profile", %{"user" => user_params}, socket) do
    # Handle avatar upload first
    avatar_path =
      consume_uploaded_entries(socket, :avatar, fn %{path: path}, _entry ->
        dest_dir = Path.join([:code.priv_dir(:insta_clone), "uploads"])
        File.mkdir_p!(dest_dir)
        filename = "#{Ecto.UUID.generate()}#{Path.extname(path)}"
        dest = Path.join(dest_dir, filename)
        File.cp!(path, dest)
        {:ok, "/uploads/#{filename}"}
      end)
      |> List.first()

    params =
      if avatar_path, do: Map.put(user_params, "avatar_path", avatar_path), else: user_params

    case Accounts.update_user_profile(socket.assigns.user, params) do
      {:ok, user} ->
        {:noreply,
         socket
         |> assign(:user, user)
         |> assign(:show_edit_modal, false)
         |> put_flash(:info, "Profile updated successfully")}

      {:error, changeset} ->
        {:noreply, assign(socket, profile_form: to_form(changeset))}
    end
  end

  def handle_event("message-user", _params, socket) do
    # Redirect to messages and pass the user_id to start a convo
    {:noreply, push_navigate(socket, to: ~p"/messages?user_id=#{socket.assigns.user.id}")}
  end

  def handle_event("open-post", %{"id" => id}, socket) do
    post = InstaClone.Timeline.get_post!(id) |> InstaClone.Repo.preload([:user, :likes])
    comments = InstaClone.Timeline.list_comments(post)
    changeset = InstaClone.Timeline.change_comment(%InstaClone.Timeline.Comment{})

    {:noreply,
     socket
     |> assign(:active_post_id, id)
     |> assign(:active_post, post)
     |> assign(:comments, comments)
     |> assign(:comment_changeset, changeset)}
  end

  def handle_event("close-comments", _params, socket) do
    {:noreply,
     socket
     |> assign(:active_post_id, nil)
     |> assign(:active_post, nil)}
  end

  @impl true
  def handle_info(:notifications_read, socket) do
    {:noreply, assign(socket, :unread_notifications_count, 0)}
  end
end
