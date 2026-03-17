defmodule InstaCloneWeb.UserLive.Registration do
  use InstaCloneWeb, :live_view

  alias InstaClone.Accounts
  alias InstaClone.Accounts.User

  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-sm">
      <div class="text-center">
        <.header>
          Register for an account
          <:subtitle>
            Already registered?
            <.link navigate={~p"/users/log-in"} class="font-semibold text-brand hover:underline">
              Log in
            </.link>
            to your account now.
          </:subtitle>
        </.header>
      </div>

      <.form
        for={@form}
        id="registration_form"
        phx-submit="save"
        phx-change="validate"
        class="mt-6 space-y-4"
      >
        <.input field={@form[:username]} type="text" label="Username" required phx-debounce="blur" />
        <.input field={@form[:full_name]} type="text" label="Full Name" required />
        <.input field={@form[:email]} type="email" label="Email" required />
        <.input field={@form[:password]} type="password" label="Password" required />

        <.button phx-disable-with="Creating account..." class="w-full">
          Create an account
        </.button>
      </.form>
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
