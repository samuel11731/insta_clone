defmodule InstaCloneWeb.TimelineLive.Index do
  use InstaCloneWeb, :live_view

  alias InstaClone.Timeline
  alias InstaClone.Accounts.Scope

  @impl true
  def mount(_params, _session, socket) do
    user = socket.assigns.current_scope.user
    scope = Scope.for_user(user)

    posts = Timeline.list_posts(scope)

    socket =
      allow_upload(socket, :photo,
        accept: ~w(.jpg .jpeg .png .webp .mp4 .mov),
        max_entries: 1,
        max_file_size: 100_000_000,
        auto_upload: true
      )

    socket =
      socket
      |> assign(:posts, posts)
      |> assign(:show_modal, false)
      |> assign(:reply_to_comment_id, nil)
      |> assign(:reply_to_user, nil)
      |> assign(:active_post_id, nil)
      |> assign(:comments, [])
      |> assign(:expanded_replies, MapSet.new())
      |> assign(:comment_changeset, Timeline.change_comment(%Timeline.Comment{}))

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
        active_post = Timeline.get_post!(post_id)
        updated_comments = Timeline.list_comments(active_post)
        assign(socket, :comments, updated_comments)
      else
        socket
      end

    {:noreply, assign(socket, :posts, posts)}
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
              System.cmd("ffmpeg", [
                "-i", path,
                "-c:v", "libx264",   # H.264 video (plays everywhere)
                "-c:a", "aac",       # AAC audio
                "-movflags", "+faststart",  # moov atom at start (needed for streaming)
                "-y",                # overwrite if exists
                out_path
              ], stderr_to_stdout: true)

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
    post = Timeline.get_post!(id)
    comments = Timeline.list_comments(post)
    changeset = Timeline.change_comment(%Timeline.Comment{})

    {:noreply,
     socket
     |> assign(:active_post_id, id)
     |> assign(:comments, comments)
     |> assign(:expanded_replies, MapSet.new())
     |> assign(:comment_changeset, changeset)}
  end

  @impl true
  def handle_event("close-comments", _params, socket) do
    {:noreply, assign(socket, :active_post_id, nil)}
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
      {:ok, _comment} ->
        comments = Timeline.list_comments(post)
        changeset = Timeline.change_comment(%Timeline.Comment{})

        {:noreply,
         socket
         |> assign(:comments, comments)
         |> assign(:comment_changeset, changeset)}

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
end
