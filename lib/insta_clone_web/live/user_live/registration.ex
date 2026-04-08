defmodule InstaCloneWeb.UserLive.Registration do
  use InstaCloneWeb, :live_view

  alias InstaClone.Accounts
  alias InstaClone.Accounts.User

  def render(assigns) do
    ~H"""
    <div class="min-h-screen flex flex-col justify-center items-center bg-gray-50 py-12 px-2 sm:px-6 lg:px-8">
      <div class="max-w-md w-full space-y-4 opacity-0 animate-fade-in-up">
        <div class="bg-white p-6 sm:p-10 shadow-sm rounded-lg">
          <div class="flex justify-center mb-6">
            <div class="bg-[#f8f8f8] rounded-lg px-8">
              <img class="h-12 w-auto" src="/logos/connect_logo.png" alt="ConnectKe" />
            </div>
          </div>

          <h2 class="text-center text-slate-500 font-bold text-sm mb-6 leading-tight">
            Sign up to see photos and videos from your friends.
            <span class="text-2xl text-orange-300">Let's connect.</span>
          </h2>

          <.form
            for={@form}
            id="registration_form"
            phx-submit="save"
            phx-change="validate"
            class="space-y-2"
          >
            <.input
              field={@form[:email]}
              type="email"
              placeholder="Email"
              required
              class="bg-gray-50 border-gray-300 text-gray-900 text-sm placeholder:text-gray-400 focus:outline-none focus:ring-1 focus:ring-[#FD4F00] focus:border-[#FD4F00] p-2 w-full rounded-md"
            />
            <.input
              field={@form[:full_name]}
              type="text"
              placeholder="Full Name"
              required
              class="bg-gray-50 border-gray-300 text-gray-900 text-sm placeholder:text-gray-400 focus:outline-none focus:ring-1 focus:ring-[#FD4F00] focus:border-[#FD4F00] p-2 w-full rounded-md"
            />
            <.input
              field={@form[:password]}
              type="password"
              placeholder="Password"
              required
              class="bg-gray-50 border-gray-300 text-gray-900 text-sm placeholder:text-gray-400 focus:outline-none focus:ring-1 focus:ring-[#FD4F00] focus:border-[#FD4F00] p-2 w-full rounded-md"
            />

            <p class="text-center text-xs text-gray-500 py-4">
              By signing up, you agree to our Terms, Data Policy and Cookies Policy.
            </p>

            <.button
              phx-disable-with="Creating account..."
              class="w-full bg-orange-400 hover:bg-orange-300 text-white font-bold py-1.5 rounded-md text-sm transition duration-200"
            >
              Sign up
            </.button>
          </.form>

          <div class="bg-white p-6 rounded-sm text-center">
            <p class="text-sm text-gray-600">
              Have an account?
              <.link
                navigate={~p"/users/log-in"}
                class="font-bold text-orange-400 hover:text-orange-300"
              >
                Log in
              </.link>
            </p>
          </div>
        </div>
      </div>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    changeset = Accounts.change_user_registration(%User{})

    socket =
      socket
      |> assign(trigger_submit: false, check_errors: false)
      |> assign_form(changeset)

    {:ok, socket, temporary_assigns: [form: nil]}
  end

  def handle_event("save", %{"user" => user_params}, socket) do
    case Accounts.register_user(user_params) do
      {:ok, _user} ->
        # SUCCESS: Redirect to login with a nice message
        {:noreply,
         socket
         |> put_flash(:info, "Account created! Please check your email to confirm.")
         |> push_navigate(to: ~p"/users/log-in")}

      {:error, %Ecto.Changeset{} = changeset} ->
        # FAILURE: We show the red error messages
        {:noreply, socket |> assign(check_errors: true) |> assign_form(changeset)}
    end
  end

  def handle_event("validate", %{"user" => user_params}, socket) do
    changeset = Accounts.change_user_registration(%User{}, user_params)
    {:noreply, assign_form(socket, Map.put(changeset, :action, :validate))}
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    form = to_form(changeset, as: "user")

    if changeset.valid? do
      assign(socket, form: form, check_errors: false)
    else
      assign(socket, form: form)
    end
  end
end
