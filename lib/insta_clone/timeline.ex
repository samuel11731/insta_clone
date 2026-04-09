defmodule InstaClone.Timeline do
  import Ecto.Query, warn: false
  alias InstaClone.Timeline.{Post, Like, Comment, CommentLike, Story, Notification}
  alias InstaClone.Accounts.Scope
  alias InstaClone.Repo

  @doc """
  Lists all active stories for the current user and those they follow.
  """
  def list_active_stories(current_user) do
    now = DateTime.utc_now()
    following_ids = InstaClone.Accounts.get_following(current_user) |> Enum.map(& &1.id)
    user_ids = [current_user.id | following_ids]

    from(s in Story,
      where: s.user_id in ^user_ids and s.expires_at > ^now,
      join: u in assoc(s, :user),
      preload: [user: u],
      order_by: [asc: s.inserted_at]
    )
    |> Repo.all()
  end

  @doc """
  Groups active stories by user for display in the story tray.
  """
  def group_active_stories_by_user(stories) do
    stories
    |> Enum.group_by(& &1.user_id)
    |> Enum.map(fn {_user_id, user_stories} ->
      %{
        user: List.first(user_stories).user,
        stories: user_stories
      }
    end)
  end

  @doc """
  Creates a story.
  """
  def create_story(%Scope{} = scope, attrs \\ %{}) do
    %Story{}
    |> Story.changeset(attrs, scope)
    |> Repo.insert()
  end

  def subscribe_posts(%Scope{} = scope) do
    key = scope.user.id

    Phoenix.PubSub.subscribe(InstaClone.PubSub, "user:#{key}:posts")
  end

  defp broadcast_post(%Scope{} = scope, message) do
    key = scope.user.id

    Phoenix.PubSub.broadcast(InstaClone.PubSub, "user:#{key}:posts", message)
  end

  def list_posts(%Scope{} = _scope) do
    Post
    |> order_by(desc: :inserted_at)
    |> preload([:user, :likes, :comments])
    |> Repo.all()
  end

  def count_user_posts(user) do
    Ecto.assoc(user, :posts)
    |> Repo.aggregate(:count, :id)
  end

  def list_user_posts(%Scope{} = _scope, user_id) do
    Post
    |> where([p], p.user_id == ^user_id)
    |> order_by(desc: :inserted_at)
    |> Repo.all()
  end

  def get_post!(%Scope{} = scope, id) do
    Repo.get_by!(Post, id: id, user_id: scope.user.id)
  end

  def get_post!(id), do: Repo.get!(Post, id)

  def create_post(%Scope{} = scope, attrs) do
    with {:ok, post = %Post{}} <-
           %Post{}
           |> Post.changeset(attrs, scope)
           |> Repo.insert() do
      broadcast_post(scope, {:created, post})
      {:ok, post}
    end
  end

  def update_post(%Scope{} = scope, %Post{} = post, attrs) do
    true = post.user_id == scope.user.id

    with {:ok, post = %Post{}} <-
           post
           |> Post.changeset(attrs, scope)
           |> Repo.update() do
      broadcast_post(scope, {:updated, post})
      {:ok, post}
    end
  end

  def delete_post(%Scope{} = scope, %Post{} = post) do
    true = post.user_id == scope.user.id

    with {:ok, post = %Post{}} <-
           Repo.delete(post) do
      broadcast_post(scope, {:deleted, post})
      {:ok, post}
    end
  end

  def change_post(%Scope{} = scope, %Post{} = post, attrs \\ %{}) do
    true = post.user_id == scope.user.id

    Post.changeset(post, attrs, scope)
  end

  def like_post(%Scope{} = scope, %Post{} = post) do
    %Like{}
    |> Like.changeset(%{user_id: scope.user.id, post_id: post.id})
    |> Repo.insert()
    |> case do
      {:ok, like} ->
        # Reload post to get owner_id
        post = Repo.get(Post, post.id)

        create_notification(%{
          actor_id: scope.user.id,
          recipient_id: post.user_id,
          type: "like",
          post_id: post.id
        })

        broadcast_to_everyone({:ok, like}, :post_updated)

      error ->
        error
    end
  end

  def unlike_post(%Scope{} = scope, %Post{} = post) do
    like = Repo.get_by(Like, user_id: scope.user.id, post_id: post.id)

    if like do
      delete_notification(%{
        actor_id: scope.user.id,
        recipient_id: post.user_id,
        type: "like",
        post_id: post.id
      })

      Repo.delete(like)
      |> broadcast_to_everyone(:post_updated)
    else
      {:error, :not_found}
    end
  end

  def liked?(%Scope{} = scope, %Post{} = post) do
    Repo.exists?(from l in Like, where: l.user_id == ^scope.user.id and l.post_id == ^post.id)
  end

  def count_likes(%Post{} = post) do
    Repo.one(from l in Like, where: l.post_id == ^post.id, select: count(l.id))
  end

  def count_comments(%Post{comments: comments}) when is_list(comments) do
    Enum.count(comments)
  end

  def count_comments(%Post{} = post) do
    Comment
    |> where([c], c.post_id == ^post.id)
    |> Repo.aggregate(:count, :id)
  end

  def format_timestamp(nil), do: ""

  def format_timestamp(%NaiveDateTime{} = naive) do
    format_timestamp(DateTime.from_naive!(naive, "Etc/UTC"))
  end

  def format_timestamp(datetime) do
    diff_seconds = DateTime.diff(DateTime.utc_now(), datetime)

    cond do
      diff_seconds < 60 -> "Just now"
      diff_seconds < 3600 -> "#{div(diff_seconds, 60)}m ago"
      diff_seconds < 86400 -> "#{div(diff_seconds, 3600)}h ago"
      diff_seconds < 604_800 -> "#{div(diff_seconds, 86400)}d ago"
      true -> "#{div(diff_seconds, 604_800)}w ago"
    end
  end

  def create_comment(%Scope{} = scope, %Post{} = post, attrs) do
    %Comment{}
    |> Comment.changeset(Map.merge(attrs, %{"user_id" => scope.user.id, "post_id" => post.id}))
    |> Repo.insert()
    |> case do
      {:ok, comment} ->
        create_notification(%{
          actor_id: scope.user.id,
          recipient_id: post.user_id,
          type: "comment",
          post_id: post.id
        })

        broadcast_to_everyone({:ok, comment}, :post_updated)

      error ->
        error
    end
  end

  def delete_comment(%Scope{} = scope, %Comment{} = comment) do
    if comment.user_id == scope.user.id do
      post = Repo.get(Post, comment.post_id)

      delete_notification(%{
        actor_id: scope.user.id,
        recipient_id: post.user_id,
        type: "comment",
        post_id: post.id
      })

      Repo.delete(comment)
      |> broadcast_to_everyone(:post_updated)
    else
      {:error, :unauthorized}
    end
  end

  def delete_story(%Scope{} = scope, %Story{} = story) do
    if story.user_id == scope.user.id do
      # Clean up the file from disk
      file_path =
        Path.join([
          :code.priv_dir(:insta_clone),
          "uploads",
          String.trim_leading(story.media_path, "/")
        ])

      File.rm(file_path)
      Repo.delete(story)
    else
      {:error, :unauthorized}
    end
  end

  def get_comment(id), do: Repo.get(Comment, id)

  def list_comments(%Post{} = post) do
    Comment
    |> where([c], c.post_id == ^post.id)
    |> order_by([c], asc: c.inserted_at)
    |> preload([:user, :likes, parent: :user])
    |> Repo.all()
  end

  def change_comment(%Comment{} = comment, attrs \\ %{}) do
    Comment.changeset(comment, attrs)
  end

  defp broadcast_to_everyone({:ok, %{post_id: post_id}} = result, event) do
    Phoenix.PubSub.broadcast(InstaClone.PubSub, "posts", {event, post_id})
    result
  end

  defp broadcast_to_everyone(error, _event), do: error

  # Comment Likes
  def like_comment(%Scope{} = scope, %Comment{} = comment) do
    case %CommentLike{}
         |> CommentLike.changeset(%{user_id: scope.user.id, comment_id: comment.id})
         |> Repo.insert() do
      {:ok, comment_like} ->
        Phoenix.PubSub.broadcast(InstaClone.PubSub, "posts", {:post_updated, comment.post_id})
        {:ok, comment_like}

      error ->
        error
    end
  end

  def unlike_comment(%Scope{} = scope, %Comment{} = comment) do
    comment_like = Repo.get_by(CommentLike, user_id: scope.user.id, comment_id: comment.id)

    if comment_like do
      case Repo.delete(comment_like) do
        {:ok, _} ->
          Phoenix.PubSub.broadcast(InstaClone.PubSub, "posts", {:post_updated, comment.post_id})
          {:ok, comment_like}

        error ->
          error
      end
    else
      {:error, :not_found}
    end
  end

  def comment_liked?(%Scope{} = scope, %Comment{} = comment) do
    Repo.exists?(
      from cl in CommentLike, where: cl.user_id == ^scope.user.id and cl.comment_id == ^comment.id
    )
  end

  def count_comment_likes(%Comment{} = comment) do
    Repo.one(from cl in CommentLike, where: cl.comment_id == ^comment.id, select: count(cl.id))
  end

  # Highlights
  def list_user_highlights(user_id) do
    from(h in InstaClone.Timeline.Highlight,
      where: h.user_id == ^user_id,
      preload: [:stories],
      order_by: [desc: h.inserted_at]
    )
    |> Repo.all()
  end

  def get_highlight(id) do
    InstaClone.Timeline.Highlight
    |> Repo.get(id)
    |> Repo.preload(:stories)
  end

  # --- Notifications ---

  def subscribe_notifications(user_id) do
    Phoenix.PubSub.subscribe(InstaClone.PubSub, "notifications:#{user_id}")
  end

  def list_notifications(user_id) do
    Notification
    |> where([n], n.recipient_id == ^user_id)
    |> order_by(desc: :inserted_at)
    |> preload([:actor, :post])
    |> Repo.all()
  end

  def count_unread_notifications(user_id) do
    Notification
    |> where([n], n.recipient_id == ^user_id and n.is_read == false)
    |> Repo.aggregate(:count, :id)
  end

  def mark_notifications_as_read(user_id) do
    from(n in Notification, where: n.recipient_id == ^user_id and n.is_read == false)
    |> Repo.update_all(set: [is_read: true, updated_at: DateTime.utc_now()])

    Phoenix.PubSub.broadcast(InstaClone.PubSub, "notifications:#{user_id}", :notifications_read)
  end

  def create_notification(attrs) do
    # Don't notify if the actor is the recipient
    if attrs.actor_id != attrs.recipient_id do
      # Check for duplicates (e.g. rapid follow/unfollow/follow)
      query =
        from(n in Notification,
          where:
            n.actor_id == ^attrs.actor_id and
              n.recipient_id == ^attrs.recipient_id and
              n.type == ^attrs.type and
              n.is_read == false
        )

      query =
        if Map.get(attrs, :post_id),
          do: where(query, [n], n.post_id == ^attrs.post_id),
          else: query

      Repo.one(query)
      |> case do
        nil ->
          %Notification{}
          |> Notification.changeset(attrs)
          |> Repo.insert()
          |> case do
            {:ok, notification} ->
              notification = Repo.preload(notification, [:actor, :post])
              broadcast_notification(notification)
              {:ok, notification}

            error ->
              error
          end

        notification ->
          {:ok, notification}
      end
    else
      {:error, :self_notification}
    end
  end

  def delete_notification(attrs) do
    query =
      from(n in Notification,
        where:
          n.actor_id == ^attrs.actor_id and
            n.recipient_id == ^attrs.recipient_id and
            n.type == ^attrs.type
      )

    query =
      if Map.get(attrs, :post_id), do: where(query, [n], n.post_id == ^attrs.post_id), else: query

    Repo.all(query)
    |> Enum.each(fn notification ->
      Repo.delete(notification)
      broadcast_notification_deleted(notification)
    end)
  end

  defp broadcast_notification(notification) do
    Phoenix.PubSub.broadcast(
      InstaClone.PubSub,
      "notifications:#{notification.recipient_id}",
      {:new_notification, notification}
    )
  end

  defp broadcast_notification_deleted(notification) do
    Phoenix.PubSub.broadcast(
      InstaClone.PubSub,
      "notifications:#{notification.recipient_id}",
      {:notification_deleted, notification.id}
    )
  end
end
