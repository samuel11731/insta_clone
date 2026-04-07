defmodule InstaCloneWeb.TimelineLive.StoryViewerComponent do
  use InstaCloneWeb, :live_component

  def render(assigns) do
    ~H"""
    <div
      id="story-viewer-modal"
      class="fixed inset-0 z-[100] bg-black text-white flex flex-col"
      phx-hook="StoryScroller"
      data-active-user={@active_story_user_id}
    >
      <!-- Scrolling Viewer Container -->
      <div
        class="flex-1 overflow-x-auto overflow-y-hidden snap-x snap-mandatory flex scrollbar-hide"
        id="stories-scroll-container"
        phx-hook="StoryAutoAdvance"
      >
        <%= for story_group <- @story_users do %>
          <div id={"story-group-#{story_group.user.id}"} class="flex h-full flex-shrink-0">
            <%= for story <- story_group.stories do %>
              <div
                class="w-screen h-full flex-shrink-0 snap-center relative bg-zinc-900 flex flex-col justify-center"
                id={"story-#{story.id}"}
                data-media-type={story.media_type}
              >
                <!-- Progress bars -->
                <div
                  class="absolute top-0 left-0 right-0 z-30 flex gap-1 p-2 pt-safe"
                  style="padding-top: max(8px, env(safe-area-inset-top));"
                >
                  <%= for {s, idx} <- Enum.with_index(story_group.stories) do %>
                    <div class="flex-1 h-[2px] bg-white/30 rounded-full overflow-hidden">
                      <div
                        id={"progress-bar-#{s.id}"}
                        class={"h-full bg-white rounded-full #{if s.id == story.id, do: "story-progress-active", else: if(idx < Enum.find_index(story_group.stories, & &1.id == story.id), do: "w-full", else: "w-0")}"}
                        style="transition: width linear;"
                      >
                      </div>
                    </div>
                  <% end %>
                </div>
                
    <!-- Header row: avatar + close button — z-40 to sit above the click overlays -->
                <div
                  class="absolute top-0 left-0 right-0 z-40 flex items-center justify-between p-3"
                  style="padding-top: max(32px, calc(env(safe-area-inset-top) + 20px));"
                >
                  <div class="flex items-center gap-2">
                    <div class="w-8 h-8 rounded-full overflow-hidden border border-white/50">
                      <img
                        src={"https://ui-avatars.com/api/?name=#{story.user.username}&background=random"}
                        class="w-full h-full object-cover"
                      />
                    </div>
                    <span class="font-semibold text-sm drop-shadow">{story.user.username}</span>
                    <span class="text-white/60 text-xs">
                      {InstaClone.Timeline.format_timestamp(story.inserted_at)}
                    </span>
                  </div>
                  <div class="flex items-center gap-2">
                    <!-- Story ⋮ menu -->
                    <div class="relative" id={"story-menu-wrap-#{story.id}"}>
                      <button
                        onclick={"document.getElementById('story-menu-#{story.id}').classList.toggle('hidden')"}
                        class="z-40 p-2 bg-black/30 hover:bg-black/60 rounded-full transition-colors"
                      >
                        <svg
                          xmlns="http://www.w3.org/2000/svg"
                          fill="currentColor"
                          viewBox="0 0 24 24"
                          class="w-4 h-4 text-white"
                        >
                          <circle cx="12" cy="5" r="1.5" /><circle cx="12" cy="12" r="1.5" /><circle
                            cx="12"
                            cy="19"
                            r="1.5"
                          />
                        </svg>
                      </button>
                      <div
                        id={"story-menu-#{story.id}"}
                        class="hidden absolute right-0 mt-1 w-52 bg-white rounded-xl shadow-2xl border border-gray-100 overflow-hidden z-50"
                      >
                        <button class="w-full text-left px-4 py-3 text-sm text-gray-700 hover:bg-gray-50 flex items-center gap-2 font-medium">
                          <svg
                            xmlns="http://www.w3.org/2000/svg"
                            fill="none"
                            viewBox="0 0 24 24"
                            stroke-width="1.5"
                            stroke="currentColor"
                            class="w-4 h-4"
                          >
                            <path
                              stroke-linecap="round"
                              stroke-linejoin="round"
                              d="M17.593 3.322c1.1.128 1.907 1.077 1.907 2.185V21L12 17.25 4.5 21V5.507c0-1.108.806-2.057 1.907-2.185a48.507 48.507 0 0111.186 0z"
                            />
                          </svg>
                          Add to Highlights
                        </button>
                        <%= if story.user_id == @active_story_user_id do %>
                          <div class="border-t border-gray-100"></div>
                          <button
                            phx-click="delete-story"
                            phx-value-id={story.id}
                            data-confirm="Delete this story?"
                            class="w-full text-left px-4 py-3 text-sm text-red-600 hover:bg-red-50 flex items-center gap-2 font-medium"
                          >
                            <svg
                              xmlns="http://www.w3.org/2000/svg"
                              fill="none"
                              viewBox="0 0 24 24"
                              stroke-width="1.5"
                              stroke="currentColor"
                              class="w-4 h-4"
                            >
                              <path
                                stroke-linecap="round"
                                stroke-linejoin="round"
                                d="M14.74 9l-.346 9m-4.788 0L9.26 9m9.968-3.21c.342.052.682.107 1.022.166m-1.022-.165L18.16 19.673a2.25 2.25 0 01-2.244 2.077H8.084a2.25 2.25 0 01-2.244-2.077L4.772 5.79m14.456 0a48.108 48.108 0 00-3.478-.397m-12 .562c.34-.059.68-.114 1.022-.165m0 0a48.11 48.11 0 013.478-.397m7.5 0v-.916c0-1.18-.91-2.164-2.09-2.201a51.964 51.964 0 00-3.32 0c-1.18.037-2.09 1.022-2.09 2.201v.916m7.5 0a48.667 48.667 0 00-7.5 0"
                              />
                            </svg>
                            Delete Story
                          </button>
                        <% end %>
                      </div>
                    </div>
                    <!-- Close button -->
                    <button
                      phx-click="close-stories"
                      class="z-40 p-2 bg-black/30 hover:bg-black/60 rounded-full transition-colors"
                    >
                      <svg
                        xmlns="http://www.w3.org/2000/svg"
                        fill="none"
                        viewBox="0 0 24 24"
                        stroke-width="2.5"
                        stroke="currentColor"
                        class="w-5 h-5"
                      >
                        <path stroke-linecap="round" stroke-linejoin="round" d="M6 18L18 6M6 6l12 12" />
                      </svg>
                    </button>
                  </div>
                </div>
                
    <!-- Media -->
                <%= if story.media_type == "video" do %>
                  <video
                    src={story.media_path}
                    class="w-full max-h-full object-contain"
                    autoplay
                    loop
                    muted
                    playsinline
                  >
                  </video>
                <% else %>
                  <img src={story.media_path} class="w-full max-h-full object-contain" />
                <% end %>
                
    <!-- Left/Right nav overlays — z-20 (below the z-40 header) -->
                <div
                  class="absolute inset-y-0 left-0 w-1/3 z-20 cursor-pointer"
                  onclick="document.getElementById('stories-scroll-container').scrollBy({left: -window.innerWidth, behavior: 'smooth'})"
                >
                </div>
                <div
                  class="absolute inset-y-0 right-0 w-1/3 z-20 cursor-pointer"
                  onclick="document.getElementById('stories-scroll-container').scrollBy({left: window.innerWidth, behavior: 'smooth'})"
                >
                </div>
              </div>
            <% end %>
          </div>
        <% end %>
      </div>
    </div>
    """
  end
end
