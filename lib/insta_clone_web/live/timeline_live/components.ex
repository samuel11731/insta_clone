defmodule InstaCloneWeb.TimelineLive.Components do
  use Phoenix.Component



  attr :comments, :list, required: true
  attr :active_post_id, :any, required: true
  attr :comment_changeset, :any, required: true
  attr :current_user, :map, required: true
  attr :reply_to_comment_id, :any, required: true
  attr :reply_to_user, :any, required: true
  attr :expanded_replies, :any, required: true
  attr :current_scope, :any, required: true

  def comments_sheet(assigns) do
    ~H"""
    <%= if @active_post_id do %>
      <div class="fixed inset-0 z-[60] bg-black/50 backdrop-blur-sm" phx-click="close-comments"></div>

      <div class="fixed bottom-0 left-0 right-0 z-[70] mx-auto w-full max-w-[470px] bg-white rounded-t-3xl shadow-xl h-[75vh] flex flex-col animate-slide-up transform transition-transform">
        <div class="w-full h-6 flex items-center justify-center pt-2" phx-click="close-comments">
          <div class="w-12 h-1 bg-gray-300 rounded-full cursor-pointer"></div>
        </div>

        <div class="border-b border-gray-100 p-3 text-center relative shrink-0">
          <h3 class="font-bold text-sm">Comments</h3>
        </div>

        <div class="flex-1 overflow-y-auto p-4 space-y-5">
          <%= if @comments == [] do %>
            <div class="text-center text-gray-400 mt-10">
              <p>No comments yet.</p>
              <p class="text-xs">Start the conversation.</p>
            </div>
          <% end %>

          <%= for comment <- Enum.filter(@comments, fn c -> is_nil(c.parent_id) end) do %>

           <div class="flex gap-3">

              <div class="w-8 h-8 rounded-full overflow-hidden bg-gray-200 shrink-0 border border-gray-100">
                <img
                  src={"https://ui-avatars.com/api/?name=#{comment.user.username}&background=random"}
                 class="w-full h-full object-cover"
                />
              </div>

              <div class="flex-1">
                <div class="text-sm">
                  <span class="font-semibold mr-2">{comment.user.username}</span>
                  <span class="text-gray-500 text-xs">
                    · {InstaClone.Timeline.format_timestamp(comment.inserted_at)}
                  </span>
                </div>

                <div class="text-sm">
                  <span>{comment.body}</span>
                </div>

                <button
                  phx-click="reply-to"
                  phx-value-id={comment.id}
                  phx-value-username={comment.user.username}
                  class="text-xs text-gray-500 font-semibold hover:text-gray-800 text-xs mt-0.5"
                >
                  Reply
                </button>

                <%= if Enum.count(@comments, fn c -> c.parent_id == comment.id end) > 0 do %>
                  <button
                    phx-click="toggle-replies"
                    phx-value-id={comment.id}
                    class="flex items-center gap-1 hover:text-gray-800 text-xs text-gray-500 font-semibold pl-4"
                  >
                    <svg
                      xmlns="http://www.w3.org/2000/svg"
                      fill="none"
                      viewBox="0 0 24 24"
                      stroke-width="2"
                      stroke="currentColor"
                      class="w-3 h-3"
                    >
                      <path
                        stroke-linecap="round"
                        stroke-linejoin="round"
                        d={
                          if MapSet.member?(@expanded_replies, comment.id),
                            do: "M19.5 8.25l-7.5 7.5-7.5-7.5",
                            else: "M8.25 4.5l7.5 7.5-7.5 7.5"
                        }
                      />
                    </svg>
                    <span>
                      <%= if MapSet.member?(@expanded_replies, comment.id) do %>
                        Hide replies
                      <% else %>
                        View {Enum.count(@comments, fn c -> c.parent_id == comment.id end)} {if Enum.count(
                                                                                                  @comments,
                                                                                                  fn c ->
                                                                                                    c.parent_id ==
                                                                                                      comment.id
                                                                                                  end
                                                                                                ) == 1,
                                                                                                do:
                                                                                                  "reply",
                                                                                                else:
                                                                                                  "replies"}
                      <% end %>
                    </span>
                  </button>
                <% end %>

                <%= if MapSet.member?(@expanded_replies, comment.id) do %>
                  <%= for reply <- Enum.filter(@comments, fn c -> c.parent_id == comment.id end) do %>
                    <div class="flex gap-3 mt-3 pl-0">
                      <div class="w-6 h-6 rounded-full overflow-hidden bg-gray-200 shrink-0 border border-gray-100">
                        <img
                          src={"https://ui-avatars.com/api/?name=#{reply.user.username}&background=random"}
                          class="w-full h-full object-cover"
                        />
                      </div>
                      <div class="flex-1">
                        <div class="text-sm">
                          <span class="font-semibold mr-1">{reply.user.username}</span>
                          <span class="text-blue-500 mr-1">@{comment.user.username}</span>
                          <span>{reply.body}</span>
                        </div>
                        <div class="flex items-center gap-4 mt-1 text-xs text-gray-500 font-semibold">
                          <span>{InstaClone.Timeline.format_timestamp(reply.inserted_at)}</span>
                          <button
                            phx-click="reply-to"
                            phx-value-id={comment.id}
                            phx-value-username={comment.user.username}
                            class="hover:text-gray-800"
                          >
                            Reply
                          </button>
                        </div>
                      </div>
                      <button
                        phx-click={
                          if InstaClone.Timeline.comment_liked?(@current_scope, reply),
                            do: "unlike-comment",
                            else: "like-comment"
                        }
                        phx-value-id={reply.id}
                        class="self-start mt-2 flex items-center gap-1 group"
                      >
                        <%= if InstaClone.Timeline.comment_liked?(@current_scope, reply) do %>
                          <svg
                            xmlns="http://www.w3.org/2000/svg"
                            viewBox="0 0 24 24"
                            fill="currentColor"
                            class="w-4 h-4 text-red-500 transition-all duration-150 group-active:scale-125"
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
                            class="w-4 h-4 text-gray-400 transition-all duration-150 group-active:scale-125"
                          >
                            <path
                              stroke-linecap="round"
                              stroke-linejoin="round"
                              d="M21 8.25c0-2.485-2.099-4.5-4.688-4.5-1.935 0-3.597 1.126-4.312 2.733-.715-1.607-2.377-2.733-4.313-2.733C5.1 3.75 3 5.765 3 8.25c0 7.22 9 12 9 12s9-4.78 9-12z"
                            />
                          </svg>
                        <% end %>
                        <%= if InstaClone.Timeline.count_comment_likes(reply) > 0 do %>
                          <span class="text-xs text-gray-600">
                            {InstaClone.Timeline.count_comment_likes(reply)}
                          </span>
                        <% end %>
                      </button>
                    </div>
                  <% end %>
                <% end %>
              </div>
              <button
                phx-click={
                  if InstaClone.Timeline.comment_liked?(@current_scope, comment),
                    do: "unlike-comment",
                    else: "like-comment"
                }
                phx-value-id={comment.id}
                class="self-start mt-2 flex items-center gap-1 group"
              >
                <%= if InstaClone.Timeline.comment_liked?(@current_scope, comment) do %>
                  <svg
                    xmlns="http://www.w3.org/2000/svg"
                    viewBox="0 0 24 24"
                    fill="currentColor"
                    class="w-4 h-4 text-red-500 transition-all duration-150 group-active:scale-125"
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
                    class="w-4 h-4 text-gray-400 transition-all duration-150 group-active:scale-125"
                  >
                    <path
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      d="M21 8.25c0-2.485-2.099-4.5-4.688-4.5-1.935 0-3.597 1.126-4.312 2.733-.715-1.607-2.377-2.733-4.313-2.733C5.1 3.75 3 5.765 3 8.25c0 7.22 9 12 9 12s9-4.78 9-12z"
                    />
                  </svg>
                <% end %>
                <%= if InstaClone.Timeline.count_comment_likes(comment) > 0 do %>
                  <span class="text-xs text-gray-600">
                    {InstaClone.Timeline.count_comment_likes(comment)}
                  </span>
                <% end %>
              </button>
            </div>
          <% end %>
        </div>

        <%= if @reply_to_user do %>
          <div class="flex items-center justify-between bg-gray-50 px-4 py-2 text-xs text-gray-500 mb-2 rounded-lg">
            <span>Replying to <span class="font-bold text-black">@{@reply_to_user}</span></span>
            <button phx-click="cancel-reply" class="text-gray-400 hover:text-red-500 font-bold">
              ✕
            </button>
          </div>
        <% end %>

    <!-- Input Area -->
        <div class="border-t border-gray-100 p-4 pb-8 shrink-0 bg-white">
          <.form
            :let={f}
            for={@comment_changeset}
            phx-submit="save-comment"
            class="flex items-center gap-3"
          >
            <div class="w-8 h-8 rounded-full overflow-hidden bg-red-500 shrink-0">
              <img
                src={"https://ui-avatars.com/api/?name=#{@current_user.username}"}
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
              class="text-blue-500 font-semibold text-sm disabled:opacity-50 hover:text-blue-600"
            >
              Post
            </button>
          </.form>
        </div>
      </div>
    <% end %>
    """
  end
end
defmodule InstaCloneWeb.TimelineLive.Components do
  use Phoenix.Component


  attr :comments, :list, required: true
  attr :active_post_id, :any, required: true
  attr :comment_changeset, :any, required: true
  attr :current_user, :map, required: true
  attr :reply_to_comment_id, :any, required: true
  attr :reply_to_user, :any, required: true
  attr :expanded_replies, :any, required: true
  attr :current_scope, :any, required: true

  def comments_sheet(assigns) do
    ~H"""
    <%= if @active_post_id do %>
      <div class="fixed inset-0 z-[60] bg-black/50 backdrop-blur-sm" phx-click="close-comments"></div>

      <div class="fixed bottom-0 left-0 right-0 z-[70] mx-auto w-full max-w-[470px] bg-white rounded-t-3xl shadow-xl h-[75vh] flex flex-col animate-slide-up transform transition-transform">
        <div class="w-full h-6 flex items-center justify-center pt-2" phx-click="close-comments">
          <div class="w-12 h-1 bg-gray-300 rounded-full cursor-pointer"></div>
        </div>

        <div class="border-b border-gray-100 p-3 text-center relative shrink-0">
          <h3 class="font-bold text-sm">Comments</h3>
        </div>

        <div class="flex-1 overflow-y-auto p-4 space-y-5">
          <%= if @comments == [] do %>
            <div class="text-center text-gray-400 mt-10">
              <p>No comments yet.</p>
              <p class="text-xs">Start the conversation.</p>
            </div>
          <% end %>

          <%= for comment <- Enum.filter(@comments, fn c -> is_nil(c.parent_id) end) do %>

           <div class="flex gap-3">

              <.link navigate={"/#{comment.user.username}"} class="w-8 h-8 rounded-full overflow-hidden bg-gray-200 shrink-0 border border-gray-100">
                <img
                  src={"https://ui-avatars.com/api/?name=#{comment.user.username}&background=random"}
                 class="w-full h-full object-cover"
                />
              </.link>

              <div class="flex-1">
                <div class="text-sm">
                  <.link navigate={"/#{comment.user.username}"} class="font-semibold mr-2">{comment.user.username}</.link>
                  <span class="text-gray-500 text-xs">
                    · {InstaClone.Timeline.format_timestamp(comment.inserted_at)}
                  </span>
                </div>

                <div class="text-sm">
                  <span>{comment.body}</span>
                </div>

                <button
                  phx-click="reply-to"
                  phx-value-id={comment.id}
                  phx-value-username={comment.user.username}
                  class="text-xs text-gray-500 font-semibold hover:text-gray-800 text-xs mt-0.5"
                >
                  Reply
                </button>

                <%= if Enum.count(@comments, fn c -> c.parent_id == comment.id end) > 0 do %>
                  <button
                    phx-click="toggle-replies"
                    phx-value-id={comment.id}
                    class="flex items-center gap-1 hover:text-gray-800 text-xs text-gray-500 font-semibold pl-4"
                  >
                    <svg
                      xmlns="http://www.w3.org/2000/svg"
                      fill="none"
                      viewBox="0 0 24 24"
                      stroke-width="2"
                      stroke="currentColor"
                      class="w-3 h-3"
                    >
                      <path
                        stroke-linecap="round"
                        stroke-linejoin="round"
                        d={
                          if MapSet.member?(@expanded_replies, comment.id),
                            do: "M19.5 8.25l-7.5 7.5-7.5-7.5",
                            else: "M8.25 4.5l7.5 7.5-7.5 7.5"
                        }
                      />
                    </svg>
                    <span>
                      <%= if MapSet.member?(@expanded_replies, comment.id) do %>
                        Hide replies
                      <% else %>
                        View {Enum.count(@comments, fn c -> c.parent_id == comment.id end)} {if Enum.count(
                                                                                                  @comments,
                                                                                                  fn c ->
                                                                                                    c.parent_id ==
                                                                                                      comment.id
                                                                                                  end
                                                                                                ) == 1,
                                                                                                do:
                                                                                                  "reply",
                                                                                                else:
                                                                                                  "replies"}
                      <% end %>
                    </span>
                  </button>
                <% end %>

                <%= if MapSet.member?(@expanded_replies, comment.id) do %>
                  <%= for reply <- Enum.filter(@comments, fn c -> c.parent_id == comment.id end) do %>
                    <div class="flex gap-3 mt-3 pl-0">
                      <div class="w-6 h-6 rounded-full overflow-hidden bg-gray-200 shrink-0 border border-gray-100">
                        <img
                          src={"https://ui-avatars.com/api/?name=#{reply.user.username}&background=random"}
                          class="w-full h-full object-cover"
                        />
                      </div>
                      <div class="flex-1">
                        <div class="text-sm">
                          <.link navigate={"/#{reply.user.username}"} class="font-semibold mr-1">{reply.user.username}</.link>
                          <span class="text-blue-500 mr-1">@{comment.user.username}</span>
                          <span>{reply.body}</span>
                        </div>
                        <div class="flex items-center gap-4 mt-1 text-xs text-gray-500 font-semibold">
                          <span>{InstaClone.Timeline.format_timestamp(reply.inserted_at)}</span>
                          <button
                            phx-click="reply-to"
                            phx-value-id={comment.id}
                            phx-value-username={comment.user.username}
                            class="hover:text-gray-800"
                          >
                            Reply
                          </button>
                        </div>
                      </div>
                      <button
                        phx-click={
                          if InstaClone.Timeline.comment_liked?(@current_scope, reply),
                            do: "unlike-comment",
                            else: "like-comment"
                        }
                        phx-value-id={reply.id}
                        class="self-start mt-2 flex items-center gap-1 group"
                      >
                        <%= if InstaClone.Timeline.comment_liked?(@current_scope, reply) do %>
                          <svg
                            xmlns="http://www.w3.org/2000/svg"
                            viewBox="0 0 24 24"
                            fill="currentColor"
                            class="w-4 h-4 text-red-500 transition-all duration-150 group-active:scale-125"
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
                            class="w-4 h-4 text-gray-400 transition-all duration-150 group-active:scale-125"
                          >
                            <path
                              stroke-linecap="round"
                              stroke-linejoin="round"
                              d="M21 8.25c0-2.485-2.099-4.5-4.688-4.5-1.935 0-3.597 1.126-4.312 2.733-.715-1.607-2.377-2.733-4.313-2.733C5.1 3.75 3 5.765 3 8.25c0 7.22 9 12 9 12s9-4.78 9-12z"
                            />
                          </svg>
                        <% end %>
                        <%= if InstaClone.Timeline.count_comment_likes(reply) > 0 do %>
                          <span class="text-xs text-gray-600">
                            {InstaClone.Timeline.count_comment_likes(reply)}
                          </span>
                        <% end %>
                      </button>
                    </div>
                  <% end %>
                <% end %>
              </div>
              <button
                phx-click={
                  if InstaClone.Timeline.comment_liked?(@current_scope, comment),
                    do: "unlike-comment",
                    else: "like-comment"
                }
                phx-value-id={comment.id}
                class="self-start mt-2 flex items-center gap-1 group"
              >
                <%= if InstaClone.Timeline.comment_liked?(@current_scope, comment) do %>
                  <svg
                    xmlns="http://www.w3.org/2000/svg"
                    viewBox="0 0 24 24"
                    fill="currentColor"
                    class="w-4 h-4 text-red-500 transition-all duration-150 group-active:scale-125"
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
                    class="w-4 h-4 text-gray-400 transition-all duration-150 group-active:scale-125"
                  >
                    <path
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      d="M21 8.25c0-2.485-2.099-4.5-4.688-4.5-1.935 0-3.597 1.126-4.312 2.733-.715-1.607-2.377-2.733-4.313-2.733C5.1 3.75 3 5.765 3 8.25c0 7.22 9 12 9 12s9-4.78 9-12z"
                    />
                  </svg>
                <% end %>
                <%= if InstaClone.Timeline.count_comment_likes(comment) > 0 do %>
                  <span class="text-xs text-gray-600">
                    {InstaClone.Timeline.count_comment_likes(comment)}
                  </span>
                <% end %>
              </button>
            </div>
          <% end %>
        </div>

        <%= if @reply_to_user do %>
          <div class="flex items-center justify-between bg-gray-50 px-4 py-2 text-xs text-gray-500 mb-2 rounded-lg">
            <span>Replying to <span class="font-bold text-black">@{@reply_to_user}</span></span>
            <button phx-click="cancel-reply" class="text-gray-400 hover:text-red-500 font-bold">
              ✕
            </button>
          </div>
        <% end %>

    <!-- Input Area -->
        <div class="border-t border-gray-100 p-4 pb-8 shrink-0 bg-white">
          <.form
            :let={f}
            for={@comment_changeset}
            phx-submit="save-comment"
            class="flex items-center gap-3"
          >
            <div class="w-8 h-8 rounded-full overflow-hidden bg-gray-200 shrink-0">
              <img
                src={"https://ui-avatars.com/api/?name=#{@current_user.username}"}
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
              class="text-blue-500 font-semibold text-sm disabled:opacity-50 hover:text-blue-600"
            >
              Post
            </button>
          </.form>
        </div>
      </div>
    <% end %>
    """
  end
end
