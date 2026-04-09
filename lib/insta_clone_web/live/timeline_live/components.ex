defmodule InstaCloneWeb.TimelineLive.Components do
  use InstaCloneWeb, :html

  attr :comments, :list, required: true
  attr :active_post_id, :any, required: true
  attr :comment_changeset, :any, required: true
  attr :current_user, :map, required: true
  attr :reply_to_user, :any, required: true
  attr :expanded_replies, :any, required: true
  attr :current_scope, :map, required: true
  attr :open_comment_menu, :any, default: nil
  attr :active_post, :any, default: nil
  attr :on_close, :any, default: nil
  attr :reply_to_comment_id, :any, default: nil

  def comments_sheet(assigns) do
    ~H"""
    <%= if @active_post_id && @active_post do %>
      <% # Overlay %>
      <div class="fixed inset-0 z-[60] bg-black/70 backdrop-blur-sm" phx-click="close-comments"></div>

      <% # Mobile Bottom Sheet %>
      <div class="md:hidden fixed bottom-0 left-0 right-0 z-[70] mx-auto w-full max-w-[470px] bg-white rounded-t-3xl shadow-xl h-[75vh] grid grid-rows-[auto_auto_1fr_auto] overflow-hidden animate-slide-up transform transition-transform">
        <div class="w-full h-6 flex items-center justify-center pt-2" phx-click="close-comments">
          <div class="w-12 h-1 bg-gray-300 rounded-full cursor-pointer"></div>
        </div>

        <div class="border-b border-gray-100 p-3 text-center relative shrink-0">
          <h3 class="font-bold text-sm">Comments</h3>
        </div>

        <div
          class="overflow-y-auto overscroll-contain p-4 space-y-5 scroll-smooth"
          id="comments-scroll-area-mobile"
        >
          <% top_level_comments = Enum.filter(@comments, &is_nil(&1.parent_id)) %>

          <%= if Enum.empty?(top_level_comments) do %>
            <div class="flex flex-col items-center justify-center h-48 text-gray-400">
              <p class="font-semibold text-gray-500">No comments yet.</p>
              <p class="text-sm">Start the conversation.</p>
            </div>
          <% else %>
            <.render_comments_list
              comments={top_level_comments}
              all_comments={@comments}
              current_scope={@current_scope}
              expanded_replies={@expanded_replies}
              open_comment_menu={@open_comment_menu}
            />
          <% end %>
        </div>

        <.comment_form_section
          comment_changeset={@comment_changeset}
          reply_to_user={@reply_to_user}
          current_user={@current_user}
        />
      </div>

      <% # Desktop Split-Pane Modal %>
      <div class="hidden md:flex fixed inset-0 z-[70] items-center justify-center p-10 pointer-events-none">
        <div class="pointer-events-auto bg-white w-full max-w-[1035px] h-full max-h-[90vh] flex rounded-lg overflow-hidden shadow-2xl">
          <% # Left Column: Media %>
          <div class="flex-1 bg-black flex items-center justify-center min-w-0 relative">
            <%= if String.ends_with?(@active_post.image_path || "", [".mp4", ".mov"]) do %>
              <video
                src={@active_post.image_path}
                autoplay
                muted
                loop
                playsinline
                class="w-full h-full object-cover"
              />
            <% else %>
              <img src={@active_post.image_path} class="w-full h-full object-cover" />
            <% end %>
          </div>

          <% # Right Column: Details & Comments %>
          <div class="w-[400px] flex flex-col bg-white border-l border-gray-100">
            <% # Header: User Info %>
            <div class="flex items-center justify-between p-4 border-b border-gray-100">
              <div class="flex items-center gap-3">
                <.link
                  navigate={"/#{@active_post.user.username}"}
                  class="w-8 h-8 rounded-full overflow-hidden border border-gray-100"
                >
                  <.user_avatar
                    src={@active_post.user.avatar_path}
                    username={@active_post.user.username}
                    class="w-full h-full object-cover"
                  />
                </.link>
                <.link
                  navigate={"/#{@active_post.user.username}"}
                  class="text-sm font-bold hover:text-gray-600 transition-colors"
                >
                  {@active_post.user.username}
                </.link>
              </div>
              <button
                phx-click="close-comments"
                class="text-gray-400 hover:text-black transition-colors"
              >
                <svg
                  xmlns="http://www.w3.org/2000/svg"
                  fill="none"
                  viewBox="0 0 24 24"
                  stroke-width="2"
                  stroke="currentColor"
                  class="w-5 h-5"
                >
                  <path stroke-linecap="round" stroke-linejoin="round" d="M6 18L18 6M6 6l12 12" />
                </svg>
              </button>
            </div>

            <% # Scrollable Body: Caption + Comments %>
            <div class="flex-1 overflow-y-auto p-4 space-y-6" id="comments-scroll-area-desktop">
              <% # Caption Row %>
              <div class="flex gap-3">
                <.link
                  navigate={"/#{@active_post.user.username}"}
                  class="w-8 h-8 rounded-full overflow-hidden shrink-0 border border-gray-100"
                >
                  <.user_avatar
                    src={@active_post.user.avatar_path}
                    username={@active_post.user.username}
                    class="w-full h-full object-cover"
                  />
                </.link>
                <div class="text-sm">
                  <p>
                    <.link
                      navigate={"/#{@active_post.user.username}"}
                      class="font-bold mr-2 hover:text-gray-600 transition-colors"
                    >
                      {@active_post.user.username}
                    </.link>
                    <span class="text-gray-900">{@active_post.caption}</span>
                  </p>
                  <p class="text-gray-500 text-xm mt-2">
                    {InstaClone.Timeline.format_timestamp(@active_post.inserted_at)}
                  </p>
                </div>
              </div>

              <% # Comments List %>
              <% top_level_comments = Enum.filter(@comments, &is_nil(&1.parent_id)) %>

              <%= if Enum.empty?(top_level_comments) do %>
                <div class="flex flex-col items-center justify-center h-full text-gray-400">
                  <p class="font-semibold text-gray-900 text-sm">No comments yet.</p>
                  <p class="text-sm">Start the conversation.</p>
                </div>
              <% else %>
                <.render_comments_list
                  comments={top_level_comments}
                  all_comments={@comments}
                  current_scope={@current_scope}
                  expanded_replies={@expanded_replies}
                  open_comment_menu={@open_comment_menu}
                />
              <% end %>
            </div>

            <% # Footer: Actions, Stats, Input %>
            <div class="border-t border-gray-100">
              <div class="p-4 bg-white">
                <div class="flex items-center justify-between mb-2">
                  <div class="flex items-center gap-4">
                    <button
                      phx-click="toggle-like"
                      phx-value-id={@active_post.id}
                      class="hover:scale-110 transition-transform active:scale-95"
                    >
                      <%= if InstaClone.Timeline.liked?(@current_scope, @active_post) do %>
                        <svg
                          xmlns="http://www.w3.org/2000/svg"
                          viewBox="0 0 24 24"
                          fill="currentColor"
                          class="w-6 h-6 text-red-500"
                        >
                          <path d="M11.645 20.91l-.007-.003-.022-.012a15.247 15.247 0 01-.383-.218 25.18 25.18 0 01-4.244-3.17C4.688 15.36 2.25 12.174 2.25 8.25 2.25 5.322 4.714 3 7.688 3A5.5 5.5 0 0112 5.052 5.5 5.5 0 0116.313 3c2.973 0 5.437 2.322 5.437 5.25 0 3.925-2.438 7.111-4.739 9.256a25.175 25.175 0 01-4.244 3.17 15.247 15.247 0 01-.383.219l-.022.012-.007.004-.003.001a.752.752 0 01-.704 0l-.003-.001z" />
                        </svg>
                      <% else %>
                        <svg
                          xmlns="http://www.w3.org/2000/svg"
                          fill="none"
                          viewBox="0 0 24 24"
                          stroke-width="1.5"
                          stroke="currentColor"
                          class="w-6 h-6 hover:text-gray-600"
                        >
                          <path
                            stroke-linecap="round"
                            stroke-linejoin="round"
                            d="M21 8.25c0-2.485-2.099-4.5-4.688-4.5-1.935 0-3.597 1.126-4.312 2.733-.715-1.607-2.377-2.733-4.313-2.733C5.1 3.75 3 5.765 3 8.25c0 7.22 9 12 9 12s9-4.78 9-12z"
                          />
                        </svg>
                      <% end %>
                    </button>
                    <button class="hover:text-gray-600 transition-colors">
                      <svg
                        xmlns="http://www.w3.org/2000/svg"
                        fill="none"
                        viewBox="0 0 24 24"
                        stroke-width="1.5"
                        stroke="currentColor"
                        class="w-6 h-6"
                      >
                        <path
                          stroke-linecap="round"
                          stroke-linejoin="round"
                          d="M7.5 8.25h9m-9 3H12m-9.75 1.51c0 1.6 1.123 2.994 2.707 3.227 1.129.166 2.27.293 3.423.379.35.026.67.21.865.501L12 21l2.755-4.133a1.14 1.14 0 0 1 .865-.501 48.172 48.172 0 0 0 3.423-.379c1.584-.233 2.707-1.626 2.707-3.228V6.741c0-1.602-1.123-2.995-2.707-3.228A48.394 48.394 0 0 0 12 3c-2.392 0-4.744.175-7.043.513C3.373 3.746 2.25 5.14 2.25 6.741v6.018Z"
                        />
                      </svg>
                    </button>
                  </div>
                </div>
                <p class="font-bold text-sm mb-1">
                  {InstaClone.Timeline.count_likes(@active_post)} likes
                </p>
                <p class="text-gray-500 text-xs">
                  {InstaClone.Timeline.format_timestamp(@active_post.inserted_at)}
                </p>
              </div>
              <.comment_form_section
                comment_changeset={@comment_changeset}
                reply_to_user={@reply_to_user}
                current_user={@current_user}
              />
            </div>
          </div>
        </div>
      </div>
    <% end %>
    """
  end

  defp comment_form_section(assigns) do
    ~H"""
    <div class="border-t border-gray-100 p-4 bg-white w-full">
      <%= if @reply_to_user do %>
        <div class="flex items-center justify-between bg-gray-50 px-4 py-2 text-xs text-gray-500 mb-2 rounded-lg">
          <span>Replying to <span class="font-bold text-black">@{@reply_to_user}</span></span>
          <button
            phx-click="cancel-reply"
            class="text-gray-400 hover:text-red-500 font-bold transition-colors"
          >
            ✕
          </button>
        </div>
      <% end %>

      <.form
        :let={f}
        for={@comment_changeset}
        phx-submit="save-comment"
        class="flex items-center gap-3"
      >
        <div class="w-8 h-8 rounded-full overflow-hidden bg-gray-200 shrink-0">
          <.user_avatar
            src={@current_user.avatar_path}
            username={@current_user.username}
            class="w-full h-full object-cover"
          />
        </div>
        <div class="flex-1 relative">
          <input
            type="text"
            name={f[:body].name}
            id={f[:body].id}
            value={f[:body].value}
            placeholder="Add a comment..."
            class="w-full bg-transparent border-none outline-none focus:ring-0 focus:outline-none text-sm placeholder-gray-400"
            autocomplete="off"
          />
        </div>
        <button
          type="submit"
          class="text-blue-500 font-semibold text-sm disabled:opacity-50 hover:text-blue-600 transition-colors"
        >
          Post
        </button>
      </.form>
    </div>
    """
  end

  defp render_comments_list(assigns) do
    assigns = assign_new(assigns, :all_comments, fn -> assigns.comments end)

    ~H"""
    <div class="space-y-6">
      <%= for comment <- @comments do %>
        <div class="flex gap-3 group/comment" id={"comment-#{comment.id}"}>
          <.link
            navigate={"/#{comment.user.username}"}
            class="w-8 h-8 rounded-full overflow-hidden bg-gray-200 shrink-0 border border-gray-100"
          >
            <.user_avatar
              src={comment.user.avatar_path}
              username={comment.user.username}
              class="w-full h-full object-cover"
            />
          </.link>

          <div class="flex-1 min-w-0">
            <div class="text-sm">
              <div class="flex items-center gap-2 mb-0.5">
                <.link
                  navigate={"/#{comment.user.username}"}
                  class="font-bold hover:text-gray-600 transition-colors"
                >
                  {comment.user.username}
                </.link>
                <span class="text-gray-400 text-xs">
                  {InstaClone.Timeline.format_timestamp(comment.inserted_at)}
                </span>
              </div>
              <p class="text-gray-900 leading-normal break-words">{comment.body}</p>
            </div>
            <div class="flex items-center gap-4 mt-2 text-[11px] text-gray-400 font-semibold">
              <%= if InstaClone.Timeline.count_comment_likes(comment) > 0 do %>
                <span class="hover:underline cursor-pointer">
                  {InstaClone.Timeline.count_comment_likes(comment)} likes
                </span>
              <% end %>
              <button
                phx-click="reply-to"
                phx-value-id={comment.id}
                phx-value-username={comment.user.username}
                class="hover:text-gray-600 transition-colors"
              >
                Reply
              </button>

              <% # Menu Trigger %>

              <div class={"relative inline-block opacity-100 md:opacity-0 group-hover/comment:opacity-100 transition-opacity #{if @open_comment_menu == comment.id, do: "z-[100]", else: "z-0"}"}>
                <button
                  phx-click="toggle-comment-menu"
                  phx-value-id={comment.id}
                  class="text-gray-400 hover:text-gray-600"
                >
                  <svg
                    xmlns="http://www.w3.org/2000/svg"
                    fill="currentColor"
                    viewBox="0 0 16 16"
                    class="w-3 h-3"
                  >
                    <path d="M9.5 13a1.5 1.5 0 1 1-3 0 1.5 1.5 0 0 1 3 0zm0-5a1.5 1.5 0 1 1-3 0 1.5 1.5 0 0 1 3 0zm0-5a1.5 1.5 0 1 1-3 0 1.5 1.5 0 0 1 3 0z" />
                  </svg>
                </button>
                <%= if @open_comment_menu == comment.id do %>
                  <div class="absolute left-0 bottom-8 w-32 bg-white rounded-lg shadow-xl border border-gray-100 overflow-hidden z-[110]">
                    <%= if comment.user_id == @current_scope.user.id do %>
                      <button
                        phx-click="delete-comment"
                        phx-value-id={comment.id}
                        data-confirm="Delete comment?"
                        class="w-full text-left px-3 py-2 text-xs text-red-500 hover:bg-red-50 font-semibold"
                      >
                        Delete
                      </button>
                    <% else %>
                      <button class="w-full text-left px-3 py-2 text-xs text-gray-700 hover:bg-gray-50 font-semibold">
                        Report
                      </button>
                    <% end %>
                  </div>
                <% end %>
              </div>
            </div>

            <% # Replied Section %>
            <%= if Enum.count(@all_comments, fn c -> c.parent_id == comment.id end) > 0 do %>
              <button
                phx-click="toggle-replies"
                phx-value-id={comment.id}
                class="flex items-center gap-2 mt-2 text-xs text-gray-500 font-semibold hover:text-gray-800 transition-colors"
              >
                <div class="w-6 h-[1px] bg-gray-300"></div>
                <%= if MapSet.member?(@expanded_replies, comment.id) do %>
                  Hide replies
                <% else %>
                  View all {Enum.count(@all_comments, fn c -> c.parent_id == comment.id end)} replies
                <% end %>
              </button>
            <% end %>

            <%= if MapSet.member?(@expanded_replies, comment.id) do %>
              <div class="space-y-4 mt-4">
                <%= for reply <- Enum.filter(@all_comments, fn c -> c.parent_id == comment.id end) do %>
                  <div class="flex gap-3 group/reply" id={"comment-#{reply.id}"}>
                    <.link
                      navigate={"/#{reply.user.username}"}
                      class="w-6 h-6 rounded-full overflow-hidden shrink-0 border border-gray-100"
                    >
                      <.user_avatar
                        src={reply.user.avatar_path}
                        username={reply.user.username}
                        class="w-full h-full object-cover"
                      />
                    </.link>
                    <div class="flex-1 min-w-0">
                      <div class="text-sm">
                        <div class="flex items-center gap-2 mb-0.5">
                          <.link
                            navigate={"/#{reply.user.username}"}
                            class="font-bold hover:text-gray-600 transition-colors"
                          >
                            {reply.user.username}
                          </.link>
                          <span class="text-gray-400 text-xs">
                            {InstaClone.Timeline.format_timestamp(reply.inserted_at)}
                          </span>
                        </div>
                        <p class="text-gray-900 leading-normal break-words">
                          <span class="text-blue-500 mr-1 cursor-pointer">
                            @{comment.user.username}
                          </span>
                          {reply.body}
                        </p>
                      </div>
                      <div class="flex items-center gap-4 mt-2 text-[11px] text-gray-400 font-semibold">
                        <%= if InstaClone.Timeline.count_comment_likes(reply) > 0 do %>
                          <span class="hover:underline cursor-pointer">
                            {InstaClone.Timeline.count_comment_likes(reply)} likes
                          </span>
                        <% end %>
                        <button
                          phx-click="reply-to"
                          phx-value-id={comment.id}
                          phx-value-username={comment.user.username}
                          class="hover:text-gray-600 transition-colors"
                        >
                          Reply
                        </button>

                        <% # Reply Menu Trigger %>
                        <div class={"relative inline-block opacity-100 md:opacity-0 group-hover/reply:opacity-100 transition-opacity #{if @open_comment_menu == reply.id, do: "z-[100]", else: "z-0"}"}>
                          <button
                            phx-click="toggle-comment-menu"
                            phx-value-id={reply.id}
                            class="text-gray-400 hover:text-gray-600"
                          >
                            <svg
                              xmlns="http://www.w3.org/2000/svg"
                              fill="currentColor"
                              viewBox="0 0 16 16"
                              class="w-2.5 h-2.5"
                            >
                              <path d="M9.5 13a1.5 1.5 0 1 1-3 0 1.5 1.5 0 0 1 3 0zm0-5a1.5 1.5 0 1 1-3 0 1.5 1.5 0 0 1 3 0zm0-5a1.5 1.5 0 1 1-3 0 1.5 1.5 0 0 1 3 0z" />
                            </svg>
                          </button>
                          <%= if @open_comment_menu == reply.id do %>
                            <div class="absolute left-0 bottom-4 w-32 bg-white rounded-lg shadow-xl border border-gray-100 overflow-hidden z-[110]">
                              <%= if reply.user_id == @current_scope.user.id do %>
                                <button
                                  phx-click="delete-comment"
                                  phx-value-id={reply.id}
                                  data-confirm="Delete reply?"
                                  class="w-full text-left px-3 py-2 text-xs text-red-500 hover:bg-red-50 font-semibold"
                                >
                                  Delete
                                </button>
                              <% else %>
                                <button class="w-full text-left px-3 py-2 text-xs text-gray-700 hover:bg-gray-50 font-semibold">
                                  Report
                                </button>
                              <% end %>
                            </div>
                          <% end %>
                        </div>
                      </div>
                    </div>

                    <button
                      phx-click={
                        if InstaClone.Timeline.comment_liked?(@current_scope, reply),
                          do: "unlike-comment",
                          else: "like-comment"
                      }
                      phx-value-id={reply.id}
                      class="shrink-0 mt-1"
                    >
                      <%= if InstaClone.Timeline.comment_liked?(@current_scope, reply) do %>
                        <svg
                          xmlns="http://www.w3.org/2000/svg"
                          viewBox="0 0 24 24"
                          fill="currentColor"
                          class="w-3 h-3 text-red-500 active:scale-125 transition-transform"
                        >
                          <path d="M11.645 20.91l-.007-.003-.022-.012a15.247 15.247 0 01-.383-.218 25.18 25.18 0 01-4.244-3.17C4.688 15.36 2.25 12.174 2.25 8.25 2.25 5.322 4.714 3 7.688 3A5.5 5.5 0 0112 5.052 5.5 5.5 0 0116.313 3c2.973 0 5.437 2.322 5.437 5.25 0 3.925-2.438 7.111-4.739 9.256a25.175 25.175 0 01-4.244 3.17 15.247 15.247 0 01-.383.219l-.022.012-.007.004-.003.001a.752.752 0 01-.704 0l-.003-.001z" />
                        </svg>
                      <% else %>
                        <svg
                          xmlns="http://www.w3.org/2000/svg"
                          fill="none"
                          viewBox="0 0 24 24"
                          stroke-width="1.5"
                          stroke="currentColor"
                          class="w-3 h-3 text-gray-400 hover:text-gray-600"
                        >
                          <path
                            stroke-linecap="round"
                            stroke-linejoin="round"
                            d="M21 8.25c0-2.485-2.099-4.5-4.688-4.5-1.935 0-3.597 1.126-4.312 2.733-.715-1.607-2.377-2.733-4.313-2.733C5.1 3.75 3 5.765 3 8.25c0 7.22 9 12 9 12s9-4.78 9-12z"
                          />
                        </svg>
                      <% end %>
                    </button>
                  </div>
                <% end %>
              </div>
            <% end %>
          </div>

          <% # Like Button for Top Level Comment %>
          <button
            phx-click={
              if InstaClone.Timeline.comment_liked?(@current_scope, comment),
                do: "unlike-comment",
                else: "like-comment"
            }
            phx-value-id={comment.id}
            class="shrink-0 mt-2"
          >
            <%= if InstaClone.Timeline.comment_liked?(@current_scope, comment) do %>
              <svg
                xmlns="http://www.w3.org/2000/svg"
                viewBox="0 0 24 24"
                fill="currentColor"
                class="w-3.5 h-3.5 text-red-500 active:scale-125 transition-transform"
              >
                <path d="M11.645 20.91l-.007-.003-.022-.012a15.247 15.247 0 01-.383-.218 25.18 25.18 0 01-4.244-3.17C4.688 15.36 2.25 12.174 2.25 8.25 2.25 5.322 4.714 3 7.688 3A5.5 5.5 0 0112 5.052 5.5 5.5 0 0116.313 3c2.973 0 5.437 2.322 5.437 5.25 0 3.925-2.438 7.111-4.739 9.256a25.175 25.175 0 01-4.244 3.17 15.247 15.247 0 01-.383.219l-.022.012-.007.004-.003.001a.752.752 0 01-.704 0l-.003-.001z" />
              </svg>
            <% else %>
              <svg
                xmlns="http://www.w3.org/2000/svg"
                fill="none"
                viewBox="0 0 24 24"
                stroke-width="1.5"
                stroke="currentColor"
                class="w-3.5 h-3.5 text-gray-400 hover:text-gray-600"
              >
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  d="M21 8.25c0-2.485-2.099-4.5-4.688-4.5-1.935 0-3.597 1.126-4.312 2.733-.715-1.607-2.377-2.733-4.313-2.733C5.1 3.75 3 5.765 3 8.25c0 7.22 9 12 9 12s9-4.78 9-12z"
                />
              </svg>
            <% end %>
          </button>
        </div>
      <% end %>
    </div>
    """
  end
end
