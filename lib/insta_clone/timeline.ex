defmodule InstaClone.Timeline do
  import Ecto.Query, warn: false
  alias InstaClone.Repo
  alias InstaClone.Timeline.CommentLike
  alias InstaClone.Timeline.Post
  alias InstaClone.Accounts.Scope
  alias InstaClone.Timeline.Like
  alias InstaClone.Timeline.Comment

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
    |> preload([:user, :likes])
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
    |> broadcast_to_everyone(:post_updated)
  end

  def unlike_post(%Scope{} = scope, %Post{} = post) do
    like = Repo.get_by(Like, user_id: scope.user.id, post_id: post.id)

    if like do
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

  def count_comments(%Post{} = post) do
    Repo.one(from c in Comment, where: c.post_id == ^post.id, select: count(c.id))
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
      diff_seconds < 604800 -> "#{div(diff_seconds, 86400)}d ago"
      true -> "#{div(diff_seconds, 604800)}w ago"
    end
  end

  def create_comment(%Scope{} = scope, %Post{} = post, attrs) do
    %Comment{}
    |> Comment.changeset(Map.merge(attrs, %{"user_id" => scope.user.id, "post_id" => post.id}))
    |> Repo.insert()
    |> broadcast_to_everyone(:post_updated)
  end

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
  Repo.exists?(from cl in CommentLike, where: cl.user_id == ^scope.user.id and cl.comment_id == ^comment.id)
end
def count_comment_likes(%Comment{} = comment) do
  Repo.one(from cl in CommentLike, where: cl.comment_id == ^comment.id, select: count(cl.id))
end


end
