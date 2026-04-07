defmodule InstaCloneWeb.TimelineLive.Explore do
  use InstaCloneWeb, :live_view

  alias InstaClone.Timeline
  alias InstaClone.Accounts

  @impl true
  def mount(_params, _session, socket) do
    # Fetch posts for the explore grid, ideally randomized for discovery
    posts =
      Timeline.list_posts(socket.assigns.current_scope)
      |> Enum.shuffle()
      |> Enum.take(30)

    {:ok,
     socket
     |> assign(:posts, posts)
     |> assign(:search_query, "")
     |> assign(:search_results, [])
     |> assign(:active_post_id, nil)
     |> assign(:active_post, nil)
     |> assign(:comments, [])
     |> assign(:reply_to_user, nil)
     |> assign(:expanded_replies, MapSet.new())
     |> assign(:open_comment_menu, nil)
     |> assign(:reply_to_comment_id, nil)}
  end

  @impl true
  def handle_event("search", %{"q" => query}, socket) do
    results =
      if String.trim(query) == "" do
        []
      else
        Accounts.search_users(query)
      end

    {:noreply, assign(socket, search_query: query, search_results: results)}
  end

  @impl true
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

  @impl true
  def handle_event("close-comments", _params, socket) do
    {:noreply,
     socket
     |> assign(:active_post_id, nil)
     |> assign(:active_post, nil)}
  end
end
