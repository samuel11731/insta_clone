defmodule InstaCloneWeb.Layouts do
  @moduledoc """
  This module holds layouts and related functionality
  used by your application.
  """
  use InstaCloneWeb, :html

  # Embed all files in layouts/* within this module.
  embed_templates "layouts/*"

  @doc """
  Renders the main sidebar and mobile navigation.
  """
  attr :current_scope, :map, required: true
  attr :unread_notifications_count, :integer, default: 0
  attr :inner_content, :any, required: true

  def main_sidebar(assigns) do
    ~H"""
    <%= if @current_scope do %>
      <div class="min-h-screen relative bg-white text-black">
        <nav class="group hidden md:flex flex-col fixed left-0 top-0 h-full border-r z-50 w-[72px] hover:w-[244px] py-2 px-3 transition-all duration-300 ease-in-out bg-white border-gray-100">
          <div class="mb-6 mt-2 px-2 h-14 flex items-center overflow-hidden transition-all duration-300 bg-[#f8f8f8] rounded-lg">
            <img
              src="/logos/connect_logo.png"
              alt="ConnectKe"
              class="h-12 w-12 shrink-0 object-contain group-hover:hidden"
            />
            <img
              src="/logos/connect_logo.png"
              alt="ConnectKe"
              class="h-12 w-auto shrink-0 hidden group-hover:block transition-all duration-300"
            />
          </div>

          <div class="flex flex-col gap-1 flex-1">
            <div class="relative overflow-hidden">
              <.link
                navigate="/timeline"
                class="flex items-center p-3 rounded-xl hover:bg-orange-200 transition-all duration-200 group/item active:scale-95"
              >
                <svg
                  xmlns="http://www.w3.org/2000/svg"
                  fill="none"
                  viewBox="0 0 24 24"
                  stroke-width="1.5"
                  stroke="currentColor"
                  class="w-6 h-6 shrink-0 group-hover/item:scale-110 transition-transform"
                >
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    d="m2.25 12 8.954-8.955c.44-.439 1.152-.439 1.591 0L21.75 12M4.5 9.75v10.125c0 .621.504 1.125 1.125 1.125H9.75v-4.875c0-.621.504-1.125 1.125-1.125h2.25c.621 0 1.125.504 1.125 1.125V21h4.125c.621 0 1.125-.504 1.125-1.125V9.75M8.25 21h8.25"
                  />
                </svg>
                <span class="ml-4 text-sm font-bold opacity-0 group-hover:opacity-100 -translate-x-4 group-hover:translate-x-0 transition-all duration-300 whitespace-nowrap">
                  Home
                </span>
              </.link>
            </div>

            <div class="relative overflow-hidden">
              <.link
                navigate="/explore"
                class="flex items-center p-3 rounded-xl hover:bg-orange-200 transition-all duration-200 group/item active:scale-95 w-full"
              >
                <svg
                  xmlns="http://www.w3.org/2000/svg"
                  fill="none"
                  viewBox="0 0 24 24"
                  stroke-width="2"
                  stroke="currentColor"
                  class="w-6 h-6 shrink-0 group-hover/item:scale-110 transition-transform"
                >
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    d="M21 21l-5.197-5.197m0 0A7.5 7.5 0 105.196 5.196a7.5 7.5 0 0010.607 10.607z"
                  />
                </svg>
                <span class="ml-4 text-sm font-bold opacity-0 group-hover:opacity-100 -translate-x-4 group-hover:translate-x-0 transition-all duration-300 whitespace-nowrap">
                  Search
                </span>
              </.link>
            </div>

            <div class="relative overflow-hidden">
              <button class="flex items-center p-3 rounded-xl hover:bg-orange-200 transition-all duration-200 group/item active:scale-95 w-full">
                <svg
                  xmlns="http://www.w3.org/2000/svg"
                  fill="none"
                  viewBox="0 0 24 24"
                  stroke-width="1.5"
                  stroke="currentColor"
                  class="w-6 h-6 shrink-0 group-hover/item:scale-110 transition-transform"
                >
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    d="m15.75 10.5 4.72-4.72a.75.75 0 0 1 1.28.53v11.38a.75.75 0 0 1-1.28.53l-4.72-4.72M4.5 18.75h9a2.25 2.25 0 0 0 2.25-2.25v-9a2.25 2.25 0 0 0-2.25-2.25h-9A2.25 2.25 0 0 0 2.25 7.5v9a2.25 2.25 0 0 0 2.25 2.25z"
                  />
                </svg>
                <span class="ml-4 text-sm font-bold opacity-0 group-hover:opacity-100 -translate-x-4 group-hover:translate-x-0 transition-all duration-300 whitespace-nowrap">
                  Reels
                </span>
              </button>
            </div>

            <div class="relative overflow-hidden">
              <.link
                navigate="/messages"
                class="flex items-center p-3 rounded-xl hover:bg-orange-200 transition-all duration-200 group/item active:scale-95 w-full"
              >
                <svg
                  xmlns="http://www.w3.org/2000/svg"
                  fill="none"
                  viewBox="0 0 24 24"
                  stroke-width="1.5"
                  stroke="currentColor"
                  class="w-6 h-6 shrink-0 group-hover/item:scale-110 transition-transform"
                >
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    d="M8.625 12a.375.375 0 11-.75 0 .375.375 0 01.75 0zm0 0H8.25m4.125 0a.375.375 0 11-.75 0 .375.375 0 01.75 0zm0 0H12m4.125 0a.375.375 0 11-.75 0 .375.375 0 01.75 0zm0 0h-.375M21 12c0 4.556-4.03 8.25-9 8.25a9.764 9.764 0 01-2.555-.337A5.972 5.972 0 015.41 20.97a5.969 5.969 0 01-.474-.065 4.48 4.48 0 00.978-2.025c.09-.457-.133-.901-.467-1.226C3.93 16.178 3 14.189 3 12c0-4.556 4.03-8.25 9-8.25s9 3.694 9 8.25z"
                  />
                </svg>
                <span class="ml-4 text-sm font-bold opacity-0 group-hover:opacity-100 -translate-x-4 group-hover:translate-x-0 transition-all duration-300 whitespace-nowrap">
                  Messages
                </span>
              </.link>
            </div>

            <div class="relative overflow-hidden">
              <.link
                navigate="/notifications"
                class="flex items-center p-3 rounded-xl hover:bg-orange-200 transition-all duration-200 group/item active:scale-95 w-full relative"
              >
                <div class="relative">
                  <svg
                    xmlns="http://www.w3.org/2000/svg"
                    fill="none"
                    viewBox="0 0 24 24"
                    stroke-width="1.5"
                    stroke="currentColor"
                    class="w-6 h-6 shrink-0 group-hover/item:scale-110 transition-transform"
                  >
                    <path
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      d="M21 8.25c0-2.485-2.099-4.5-4.688-4.5-1.935 0-3.597 1.126-4.312 2.733-.715-1.607-2.377-2.733-4.313-2.733C5.1 3.75 3 5.765 3 8.25c0 7.22 9 12 9 12s9-4.78 9-12z"
                    />
                  </svg>
                  <%= if assigns[:unread_notifications_count] && @unread_notifications_count > 0 do %>
                    <span class="absolute -top-1.5 -right-1.5 flex items-center justify-center bg-red-500 text-white text-[10px] font-bold h-4 w-4 rounded-full ring-2 ring-white">
                      {@unread_notifications_count}
                    </span>
                  <% end %>
                </div>
                <span class="ml-4 text-sm font-bold opacity-0 group-hover:opacity-100 -translate-x-4 group-hover:translate-x-0 transition-all duration-300 whitespace-nowrap">
                  Notifications
                </span>
              </.link>
            </div>

            <div class="relative overflow-hidden">
              <button class="flex items-center p-3 rounded-xl hover:bg-orange-200 transition-all duration-200 group/item active:scale-95 w-full">
                <svg
                  xmlns="http://www.w3.org/2000/svg"
                  fill="none"
                  viewBox="0 0 24 24"
                  stroke-width="2"
                  stroke="currentColor"
                  class="w-6 h-6 shrink-0 group-hover/item:scale-110 transition-transform"
                >
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    d="M12 9v6m3-3H9m12 0a9 9 0 11-18 0 9 9 0 0118 0z"
                  />
                </svg>
                <span class="ml-4 text-sm font-bold opacity-0 group-hover:opacity-100 -translate-x-4 group-hover:translate-x-0 transition-all duration-300 whitespace-nowrap">
                  Create
                </span>
              </button>
            </div>

            <div class="relative overflow-hidden">
              <.link
                navigate={~p"/profile/#{@current_scope.user.username}"}
                class="flex items-center p-3 rounded-xl hover:bg-orange-200 transition-all duration-200 group/item active:scale-95"
              >
                <div class="w-6 h-6 rounded-full overflow-hidden border border-gray-300 shrink-0 group-hover/item:scale-110 transition-transform">
                  <.user_avatar
                    src={@current_scope.user.avatar_path}
                    username={@current_scope.user.username}
                    class="w-full h-full object-cover"
                  />
                </div>
                <span class="ml-4 text-sm font-bold opacity-0 group-hover:opacity-100 -translate-x-4 group-hover:translate-x-0 transition-all duration-300 whitespace-nowrap">
                  Profile
                </span>
              </.link>
            </div>
          </div>

          <div class="mt-auto">
            <div class="relative overflow-hidden">
              <.link
                href={~p"/users/log-out"}
                method="delete"
                class="flex items-center p-3 rounded-xl hover:bg-red-800 transition-all duration-200 group/item active:scale-95 text-gray-500 hover:text-white"
              >
                <svg
                  xmlns="http://www.w3.org/2000/svg"
                  fill="none"
                  viewBox="0 0 24 24"
                  stroke-width="1.5"
                  stroke="currentColor"
                  class="w-6 h-6 shrink-0 group-hover/item:scale-110 transition-transform"
                >
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    d="M3.75 6.75h16.5M3.75 12h16.5m-16.5 5.25h16.5"
                  />
                </svg>
                <span class="ml-4 text-sm font-bold opacity-0 group-hover:opacity-100 -translate-x-4 group-hover:translate-x-0 transition-all duration-300 whitespace-nowrap">
                  Log Out
                </span>
              </.link>
            </div>
          </div>
        </nav>

        <main class="flex-1 min-w-0 ml-0 md:ml-[72px]">
          {@inner_content}
        </main>
      </div>

      <div class={"fixed bottom-0 left-0 w-full border-t z-50 pb-safe md:hidden transition-colors duration-300 #{if assigns[:dark_mode], do: "bg-black border-gray-900", else: "bg-white border-gray-200"}"}>
        <div class="flex justify-between items-center px-6 py-3 mx-auto">
          <.link
            navigate="/timeline"
            class={if assigns[:dark_mode], do: "text-white", else: "text-black"}
          >
            <svg
              xmlns="http://www.w3.org/2000/svg"
              fill="none"
              viewBox="0 0 24 24"
              stroke-width="1.5"
              stroke="currentColor"
              class="w-7 h-7"
            >
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                d="m2.25 12 8.954-8.955c.44-.439 1.152-.439 1.591 0L21.75 12M4.5 9.75v10.125c0 .621.504 1.125 1.125 1.125H9.75v-4.875c0-.621.504-1.125 1.125-1.125h2.25c.621 0 1.125.504 1.125 1.125V21h4.125c.621 0 1.125-.504 1.125-1.125V9.75M8.25 21h8.25"
              />
            </svg>
          </.link>

          <.link navigate="/explore" class="text-gray-500 hover:opacity-75">
            <svg
              xmlns="http://www.w3.org/2000/svg"
              fill="none"
              viewBox="0 0 24 24"
              stroke-width="2"
              stroke="currentColor"
              class="w-7 h-7"
            >
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                d="M21 21l-5.197-5.197m0 0A7.5 7.5 0 105.196 5.196a7.5 7.5 0 0010.607 10.607z"
              />
            </svg>
          </.link>

          <button class="text-gray-500 hover:opacity-75">
            <svg
              xmlns="http://www.w3.org/2000/svg"
              fill="none"
              viewBox="0 0 24 24"
              stroke-width="2"
              stroke="currentColor"
              class="w-7 h-7"
            >
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                d="M5.25 5.653c0-.856.917-1.398 1.667-.986l11.54 6.348a1.125 1.125 0 010 1.971l-11.54 6.347a1.125 1.125 0 01-1.667-.985V5.653z"
              />
            </svg>
          </button>

          <.link navigate="/messages" class="text-gray-500 hover:opacity-75">
            <svg
              xmlns="http://www.w3.org/2000/svg"
              fill="none"
              viewBox="0 0 24 24"
              stroke-width="1.5"
              stroke="currentColor"
              class="w-7 h-7"
            >
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                d="M8.625 12a.375.375 0 11-.75 0 .375.375 0 01.75 0zm0 0H8.25m4.125 0a.375.375 0 11-.75 0 .375.375 0 01.75 0zm0 0H12m4.125 0a.375.375 0 11-.75 0 .375.375 0 01.75 0zm0 0h-.375M21 12c0 4.556-4.03 8.25-9 8.25a9.764 9.764 0 01-2.555-.337A5.972 5.972 0 015.41 20.97a5.969 5.969 0 01-.474-.065 4.48 4.48 0 00.978-2.025c.09-.457-.133-.901-.467-1.226C3.93 16.178 3 14.189 3 12c0-4.556 4.03-8.25 9-8.25s9 3.694 9 8.25z"
              />
            </svg>
          </.link>

          <.link
            navigate={~p"/profile/#{@current_scope.user.username}"}
            class="rounded-full overflow-hidden w-7 h-7 border border-gray-300 shrink-0"
          >
            <.user_avatar
              src={@current_scope.user.avatar_path}
              username={@current_scope.user.username}
              class="w-full h-full object-cover"
            />
          </.link>
        </div>
      </div>
    <% else %>
      {@inner_content}
    <% end %>
    """
  end

  @doc """
  Shows the flash group with standard titles and content.

  ## Examples

      <.flash_group flash={@flash} />
  """
  attr :flash, :map, required: true, doc: "the map of flash messages"
  attr :id, :string, default: "flash-group", doc: "the optional id of flash container"

  def flash_group(assigns) do
    ~H"""
    <div id={@id} aria-live="polite">
      <.flash kind={:info} flash={@flash} />
      <.flash kind={:error} flash={@flash} />

      <.flash
        id="client-error"
        kind={:error}
        title={gettext("We can't find the internet")}
        phx-disconnected={show(".phx-client-error #client-error") |> JS.remove_attribute("hidden")}
        phx-connected={hide("#client-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        {gettext("Attempting to reconnect")}
        <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
      </.flash>

      <.flash
        id="server-error"
        kind={:error}
        title={gettext("Something went wrong!")}
        phx-disconnected={show(".phx-server-error #server-error") |> JS.remove_attribute("hidden")}
        phx-connected={hide("#server-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        {gettext("Attempting to reconnect")}
        <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
      </.flash>
    </div>
    """
  end

  @doc """
  Provides dark vs light theme toggle based on themes defined in app.css.

  See <head> in root.html.heex which applies the theme before page load.
  """
  def theme_toggle(assigns) do
    ~H"""
    <div class="card relative flex flex-row items-center border-2 border-base-300 bg-base-300 rounded-full">
      <div class="absolute w-1/3 h-full rounded-full border-1 border-base-200 bg-base-100 brightness-200 left-0 [[data-theme=light]_&]:left-1/3 [[data-theme=dark]_&]:left-2/3 transition-[left]" />

      <button
        class="flex p-2 cursor-pointer w-1/3"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="system"
      >
        <.icon name="hero-computer-desktop-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>

      <button
        class="flex p-2 cursor-pointer w-1/3"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="light"
      >
        <.icon name="hero-sun-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>

      <button
        class="flex p-2 cursor-pointer w-1/3"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="dark"
      >
        <.icon name="hero-moon-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>
    </div>
    """
  end
end
