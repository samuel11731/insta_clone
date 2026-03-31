defmodule InstaCloneWeb.UserLive.Login do
  use InstaCloneWeb, :live_view

  alias InstaClone.Accounts

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen flex flex-col justify-center items-center bg-gray-50 py-12 px-4 sm:px-6 lg:px-8">
      <div class="max-w-sm w-full space-y-4">
        <div class="bg-white p-10 border border-gray-300 rounded-sm">
          <div class="flex justify-center mb-8">
            <img class="h-12 w-auto" src="/images/logo.svg" alt="InstaClone" />
          </div>

          <div :if={local_mail_adapter?()} class="mb-4 p-3 bg-blue-50 text-blue-700 text-xs rounded-md">
            <p>Local mail adapter: <.link href="/dev/mailbox" class="underline font-bold">view mailbox</.link></p>
          </div>

          <div class="space-y-6">
            <.form
              :let={f}
              for={@form}
              id="login_form_password"
              action={~p"/users/log-in"}
              phx-submit="submit_password"
              phx-trigger-action={@trigger_submit}
            >
              <div class="space-y-2">
                <.input
                  readonly={!!@current_scope}
                  field={f[:email]}
                  type="email"
                  placeholder="Email"
                  autocomplete="email"
                  required
                  class="bg-gray-50 border-gray-300 text-sm focus:ring-0 focus:border-gray-400"
                />
                <.input
                  field={@form[:password]}
                  type="password"
                  placeholder="Password"
                  autocomplete="current-password"
                  class="bg-gray-50 border-gray-300 text-sm focus:ring-0 focus:border-gray-400"
                />
              </div>

              <.button class="w-full mt-4 bg-sky-500 hover:bg-sky-600 text-white font-bold py-1.5 rounded-md text-sm transition duration-200">
                Log in
              </.button>

              <div class="flex items-center my-4">
                <div class="flex-grow border-t border-gray-300"></div>
                <span class="flex-shrink mx-4 text-gray-400 text-xs font-bold uppercase">OR</span>
                <div class="flex-grow border-t border-gray-300"></div>
              </div>

              <div class="text-center">
                <.link
                  phx-click={JS.toggle(to: "#magic-link-section") |> JS.toggle(to: "#password-login-hint")}
                  class="text-sm font-semibold text-blue-900"
                >
                  Log in with magic link
                </.link>
              </div>
            </.form>

            <div id="magic-link-section" class="hidden pt-4 border-t border-gray-100">
              <.form
                :let={f}
                for={@form}
                id="login_form_magic"
                action={~p"/users/log-in"}
                phx-submit="submit_magic"
              >
                <.input
                  readonly={!!@current_scope}
                  field={f[:email]}
                  type="email"
                  placeholder="Email for magic link"
                  autocomplete="email"
                  required
                  class="bg-gray-50 border-gray-300 text-sm focus:ring-0 focus:border-gray-400"
                />
                <.button class="w-full mt-2 bg-sky-100 hover:bg-sky-200 text-sky-700 font-bold py-1.5 rounded-md text-sm transition duration-200">
                  Send Link
                </.button>
              </.form>
            </div>
          </div>
        </div>

        <div class="bg-white p-6 border border-gray-300 rounded-sm text-center">
          <p class="text-sm text-gray-600">
            Don't have an account?
            <.link navigate={~p"/users/register"} class="font-bold text-sky-500 hover:text-sky-600">
              Sign up
            </.link>
          </p>
        </div>
      </div>
    </div>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    email =
      Phoenix.Flash.get(socket.assigns.flash, :email) ||
        get_in(socket.assigns, [:current_scope, Access.key(:user), Access.key(:email)])

    form = to_form(%{"email" => email}, as: "user")

    {:ok, assign(socket, form: form, trigger_submit: false)}
  end

  @impl true
  def handle_event("submit_password", _params, socket) do
    {:noreply, assign(socket, :trigger_submit, true)}
  end

  def handle_event("submit_magic", %{"user" => %{"email" => email}}, socket) do
    if user = Accounts.get_user_by_email(email) do
      Accounts.deliver_login_instructions(
        user,
        &url(~p"/users/log-in/#{&1}")
      )
    end

    info =
      "If your email is in our system, you will receive instructions for logging in shortly."

    {:noreply,
     socket
     |> put_flash(:info, info)
     |> push_navigate(to: ~p"/users/log-in")}
  end

  defp local_mail_adapter? do
    Application.get_env(:insta_clone, InstaClone.Mailer)[:adapter] == Swoosh.Adapters.Local
  end
end
