defmodule InstaCloneWeb.UserLive.Login do
  use InstaCloneWeb, :live_view

  alias InstaClone.Accounts

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen flex flex-col justify-center items-center bg-gray-50 py-12 px-2 sm:px-6 lg:px-8">
      <div class="max-w-md w-full space-y-4 opacity-0 animate-fade-in-up">
        <div class="bg-white p-6 sm:p-10 shadow-sm rounded-lg">
          <div class="flex justify-center mb-8">
            <div class="bg-[#f8f8f8] rounded-lg px-8">
              <img class="h-12 w-auto" src="/logos/connect_logo.png" alt="ConnectKe" />
            </div>
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
                  class="bg-gray-50 border-gray-300 text-gray-900 text-sm placeholder:text-gray-400 focus:outline-none focus:ring-1 focus:ring-[#FD4F00] focus:border-[#FD4F00] p-2 w-full rounded-md"
                />
                <.input
                  field={@form[:password]}
                  type="password"
                  placeholder="Password"
                  autocomplete="current-password"
                  class="bg-gray-50 border-gray-300 text-gray-900 text-sm placeholder:text-gray-400 focus:outline-none focus:ring-1 focus:ring-[#FD4F00] focus:border-[#FD4F00] p-2 w-full rounded-md"
                />
              </div>

              <.button class="w-full mt-4 bg-orange-400 hover:bg-orange-300 text-white font-bold py-1.5 rounded-md text-sm transition duration-200">
                Log in
              </.button>
            </.form>

            <div class="bg-white p-6 rounded-sm text-center">
              <p class="text-sm text-gray-600">
                Don't have an account?
                <.link
                  navigate={~p"/users/register"}
                  class="font-bold text-orange-500 hover:text-orange-300"
                >
                  Sign up
                </.link>
              </p>
              <p>
                <.link
                  navigate={~p"/users/register"}
                  class="text-sm text-orange-400 hover:text-orange-300 underline"
                >
                  forgot password?
                </.link>
              </p>
            </div>
          </div>
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
