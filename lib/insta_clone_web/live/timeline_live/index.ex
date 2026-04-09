defmodule InstaCloneWeb.TimelineLive.Index do
  use InstaCloneWeb, :live_view

  alias InstaClone.Timeline
  alias InstaClone.Accounts.Scope

  @impl true
  def mount(_params, _session, socket) do
    user = socket.assigns.current_scope.user
    scope = Scope.for_user(user)

    posts = Timeline.list_posts(scope)
    active_stories = Timeline.list_active_stories(user)
    story_users = Timeline.group_active_stories_by_user(active_stories)

    socket =
      allow_upload(socket, :photo,
        accept: ~w(.jpg .jpeg .png .webp .mp4 .mov),
        max_entries: 1,
        max_file_size: 100_000_000,
        auto_upload: true
      )
      |> allow_upload(:story_media,
        accept: ~w(.jpg .jpeg .png .webp .mp4 .mov),
        max_entries: 1,
        max_file_size: 100_000_000,
        auto_upload: true,
        progress: &handle_story_progress/3
      )

    socket =
      socket
      |> assign(:posts, posts)
      |> assign(:story_users, story_users)
      |> assign(:active_story_user_id, nil)
      |> assign(:show_modal, false)
      |> assign(:reply_to_comment_id, nil)
      |> assign(:reply_to_user, nil)
      |> assign(:active_post_id, nil)
      |> assign(:active_post, nil)
      |> assign(:comments, [])
      |> assign(:expanded_replies, MapSet.new())
      |> assign(:comment_changeset, Timeline.change_comment(%Timeline.Comment{}))
      |> assign(:open_post_menu, nil)
      |> assign(:open_comment_menu, nil)

    if connected?(socket) do
      Phoenix.PubSub.subscribe(InstaClone.PubSub, "posts")
      Phoenix.PubSub.subscribe(InstaClone.PubSub, "user:#{user.id}:posts")
    end

    {:ok, socket}
  end

  @impl true
  def handle_info({:post_updated, post_id}, socket) do
    scope = InstaClone.Accounts.Scope.for_user(socket.assigns.current_scope.user)
    posts = Timeline.list_posts(scope)

    socket =
      if socket.assigns.active_post_id == post_id do
        active_post = Timeline.get_post!(post_id) |> InstaClone.Repo.preload([:user, :likes])
        updated_comments = Timeline.list_comments(active_post)

        assign(socket, :comments, updated_comments)
        |> assign(:active_post, active_post)
      else
        socket
      end

    {:noreply, assign(socket, :posts, posts)}
  end

  @impl true
  def handle_info(:notifications_read, socket) do
    {:noreply, assign(socket, :unread_notifications_count, 0)}
  end

  @impl true
  def handle_info({:created, _post}, socket) do
    scope = InstaClone.Accounts.Scope.for_user(socket.assigns.current_scope.user)
    posts = Timeline.list_posts(scope)
    {:noreply, assign(socket, :posts, posts)}
  end

  @impl true
  def handle_event("open-modal", %{}, socket) do
    {:noreply, assign(socket, :show_modal, true)}
  end

  @impl true
  def handle_event("close-modal", %{}, socket) do
    {:noreply, assign(socket, :show_modal, false)}
  end

  @impl true
  def handle_event("validate", _params, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("validate-story", _params, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("open-stories", %{"user-id" => user_id}, socket) do
    {:noreply, assign(socket, :active_story_user_id, user_id)}
  end

  @impl true
  def handle_event("close-stories", _params, socket) do
    {:noreply, assign(socket, :active_story_user_id, nil)}
  end

  @impl true
  def handle_event("toggle-post-menu", %{"id" => post_id}, socket) do
    current = socket.assigns[:open_post_menu]
    {:noreply, assign(socket, :open_post_menu, if(current == post_id, do: nil, else: post_id))}
  end

  @impl true
  def handle_event("toggle-comment-menu", %{"id" => comment_id}, socket) do
    current = socket.assigns[:open_comment_menu]

    {:noreply,
     assign(socket, :open_comment_menu, if(current == comment_id, do: nil, else: comment_id))}
  end

  @impl true
  def handle_event("close-menus", _params, socket) do
    {:noreply, socket |> assign(:open_post_menu, nil) |> assign(:open_comment_menu, nil)}
  end

  @impl true
  def handle_event("delete-post", %{"id" => post_id}, socket) do
    scope = socket.assigns.current_scope
    post = Timeline.get_post!(post_id)

    if post.user_id == scope.user.id do
      Timeline.delete_post(scope, post)
      posts = Timeline.list_posts(scope)

      {:noreply,
       socket
       |> assign(:posts, posts)
       |> assign(:open_post_menu, nil)
       |> put_flash(:info, "Post deleted.")}
    else
      {:noreply, put_flash(socket, :error, "Unauthorized.")}
    end
  end

  @impl true
  def handle_event("delete-comment", %{"id" => comment_id}, socket) do
    scope = socket.assigns.current_scope

    case Timeline.get_comment(comment_id) do
      nil ->
        {:noreply, put_flash(socket, :error, "Comment not found.")}

      comment ->
        # Optimistic update: remove from local state immediately
        updated_comments = Enum.reject(socket.assigns.comments, &(&1.id == comment.id))
        socket = assign(socket, :comments, updated_comments)

        case Timeline.delete_comment(scope, comment) do
          {:ok, _} ->
            # Reload post and update feed for instant count update
            updated_post =
              Timeline.get_post!(socket.assigns.active_post_id)
              |> InstaClone.Repo.preload([:user, :likes, :comments])

            updated_posts =
              Enum.map(socket.assigns.posts, fn p ->
                if p.id == updated_post.id, do: updated_post, else: p
              end)

            # Final sync with DB for the comments list itself
            comments = Timeline.list_comments(updated_post)

            {:noreply,
             socket
             |> assign(:comments, comments)
             |> assign(:active_post, updated_post)
             |> assign(:posts, updated_posts)
             |> assign(:open_comment_menu, nil)}

          {:error, _} ->
            # Rollback on error (optional, but good practice)
            original_comments =
              Timeline.list_comments(Timeline.get_post!(socket.assigns.active_post_id))

            {:noreply,
             socket
             |> assign(:comments, original_comments)
             |> put_flash(:error, "Could not delete comment.")}
        end
    end
  end

  @impl true
  def handle_event("delete-story", %{"id" => story_id}, socket) do
    user = socket.assigns.current_scope.user
    scope = InstaClone.Accounts.Scope.for_user(user)

    # Direct DB lookup for safety
    case InstaClone.Repo.get(InstaClone.Timeline.Story, story_id) do
      nil ->
        {:noreply, put_flash(socket, :error, "Story not found.")}

      story ->
        Timeline.delete_story(scope, story)
        active_stories = Timeline.list_active_stories(user)
        story_users = Timeline.group_active_stories_by_user(active_stories)

        {:noreply,
         socket
         |> assign(:story_users, story_users)
         |> assign(:active_story_user_id, nil)
         |> put_flash(:info, "Story deleted.")}
    end
  end

  @impl true
  def handle_event("save", %{"caption" => caption}, socket) do
    try do
      image_paths =
        consume_uploaded_entries(socket, :photo, fn %{path: path}, entry ->
          ext = String.downcase(Path.extname(entry.client_name))
          dest_dir = Path.join([:code.priv_dir(:insta_clone), "static", "images"])
          File.mkdir_p!(dest_dir)

          if ext in [".mp4", ".mov"] do
            # Transcode to H.264/AAC so all browsers can play it
            out_filename = "#{entry.uuid}.mp4"
            out_path = Path.join(dest_dir, out_filename)

            {_output, exit_code} =
              System.cmd(
                "ffmpeg",
                [
                  "-i",
                  path,
                  # H.264 video (plays everywhere)
                  "-c:v",
                  "libx264",
                  # AAC audio
                  "-c:a",
                  "aac",
                  # moov atom at start (needed for streaming)
                  "-movflags",
                  "+faststart",
                  # overwrite if exists
                  "-y",
                  out_path
                ],
                stderr_to_stdout: true
              )

            if exit_code == 0 do
              {:ok, "/images/#{out_filename}"}
            else
              raise "FFmpeg transcoding failed (exit #{exit_code})"
            end
          else
            filename = "#{entry.uuid}#{ext}"
            dest = Path.join(dest_dir, filename)
            File.cp!(path, dest)
            {:ok, "/images/#{filename}"}
          end
        end)

      image_path = List.first(image_paths)

      if image_path do
        scope = InstaClone.Accounts.Scope.for_user(socket.assigns.current_scope.user)

        case InstaClone.Timeline.create_post(scope, %{caption: caption, image_path: image_path}) do
          {:ok, _post} ->
            {:noreply,
             socket
             |> assign(:show_modal, false)
             |> put_flash(:info, "Post shared!")}

          {:error, changeset} ->
            errors = Ecto.Changeset.traverse_errors(changeset, fn {msg, _opts} -> msg end)
            IO.inspect(errors, label: "create_post errors")

            {:noreply,
             socket
             |> put_flash(:error, "Could not save post. #{inspect(errors)}")}
        end
      else
        {:noreply,
         socket
         |> put_flash(:error, "Please select a photo before sharing.")}
      end
    rescue
      e ->
        IO.inspect(e, label: "save error")

        {:noreply,
         socket
         |> put_flash(:error, "Upload failed: #{Exception.message(e)}")}
    end
  end

  @impl true
  def handle_event("toggle-like", %{"id" => id}, socket) do
    post = Timeline.get_post!(id)
    scope = InstaClone.Accounts.Scope.for_user(socket.assigns.current_scope.user)

    if Timeline.liked?(scope, post) do
      Timeline.unlike_post(scope, post)
    else
      Timeline.like_post(scope, post)
    end

    {:noreply, socket}
  end

  @impl true
  def handle_event("open-comments", %{"id" => id}, socket) do
    post = Timeline.get_post!(id) |> InstaClone.Repo.preload([:user, :likes])
    comments = Timeline.list_comments(post)
    changeset = Timeline.change_comment(%Timeline.Comment{})

    {:noreply,
     socket
     |> assign(:active_post_id, id)
     |> assign(:active_post, post)
     |> assign(:comments, comments)
     |> assign(:expanded_replies, MapSet.new())
     |> assign(:comment_changeset, changeset)}
  end

  @impl true
  def handle_event("close-comments", _params, socket) do
    {:noreply,
     socket
     |> assign(:active_post_id, nil)
     |> assign(:active_post, nil)}
  end

  @impl true
  def handle_event("save-comment", %{"comment" => comment_params}, socket) do
    post_id = socket.assigns.active_post_id
    post = Timeline.get_post!(post_id)
    scope = InstaClone.Accounts.Scope.for_user(socket.assigns.current_scope.user)

    attrs =
      if socket.assigns.reply_to_comment_id do
        Map.put(comment_params, "parent_id", socket.assigns.reply_to_comment_id)
      else
        comment_params
      end

    case Timeline.create_comment(scope, post, attrs) do
      {:ok, comment} ->
        comments = Timeline.list_comments(post)
        changeset = Timeline.change_comment(%Timeline.Comment{})

        {:noreply,
         socket
         |> assign(:comments, comments)
         |> assign(:comment_changeset, changeset)
         |> assign(:reply_to_user, nil)
         |> assign(:reply_to_comment_id, nil)
         |> push_event("scroll-to-comment", %{id: "comment-#{comment.id}"})}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :comment_changeset, changeset)}
    end
  end

  @impl true
  def handle_event("reply-to", %{"id" => id, "username" => username}, socket) do
    {:noreply,
     socket
     |> assign(:reply_to_comment_id, id)
     |> assign(:reply_to_user, username)}
  end

  @impl true
  def handle_event("cancel-reply", _params, socket) do
    {:noreply,
     socket
     |> assign(:reply_to_comment_id, nil)
     |> assign(:reply_to_user, nil)}
  end

  @impl true
  def handle_event("toggle-replies", %{"id" => comment_id}, socket) do
    expanded = socket.assigns.expanded_replies

    new_expanded =
      if MapSet.member?(expanded, comment_id) do
        MapSet.delete(expanded, comment_id)
      else
        MapSet.put(expanded, comment_id)
      end

    {:noreply, assign(socket, :expanded_replies, new_expanded)}
  end

  @impl true
  def handle_event("like-comment", %{"id" => comment_id}, socket) do
    comment = Enum.find(socket.assigns.comments, fn c -> c.id == comment_id end)
    scope = socket.assigns.current_scope
    Timeline.like_comment(scope, comment)

    {:noreply, socket}
  end

  @impl true
  def handle_event("unlike-comment", %{"id" => comment_id}, socket) do
    comment = Enum.find(socket.assigns.comments, fn c -> c.id == comment_id end)
    scope = socket.assigns.current_scope
    Timeline.unlike_comment(scope, comment)

    {:noreply, socket}
  end

  def handle_story_progress(:story_media, entry, socket) do
    if entry.done? do
      image_paths =
        consume_uploaded_entries(socket, :story_media, fn %{path: path}, entry ->
          ext = Path.extname(entry.client_name)
          filename = "#{entry.uuid}#{ext}"
          dest_dir = Path.join([:code.priv_dir(:insta_clone), "uploads", "stories"])
          File.mkdir_p!(dest_dir)
          dest = Path.join(dest_dir, filename)
          File.cp!(path, dest)
          {:ok, "/uploads/stories/#{filename}"}
        end)

      image_path = List.first(image_paths)

      if image_path do
        scope = InstaClone.Accounts.Scope.for_user(socket.assigns.current_scope.user)

        media_type =
          if String.ends_with?(String.downcase(image_path), [".mp4", ".mov"]),
            do: "video",
            else: "image"

        case InstaClone.Timeline.create_story(scope, %{
               media_path: image_path,
               media_type: media_type
             }) do
          {:ok, _story} ->
            active_stories =
              InstaClone.Timeline.list_active_stories(socket.assigns.current_scope.user)

            story_users = InstaClone.Timeline.group_active_stories_by_user(active_stories)

            {:noreply,
             socket
             |> assign(:story_users, story_users)
             |> put_flash(:info, "Story added!")}

          {:error, _changeset} ->
            {:noreply, put_flash(socket, :error, "Could not save story.")}
        end
      else
        {:noreply, socket}
      end
    else
      {:noreply, socket}
    end
  end
end
