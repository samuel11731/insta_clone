defmodule InstaClone.Accounts do
  @moduledoc """
  The Accounts context.
  """

  import Ecto.Query, warn: false
  alias InstaClone.Repo

  alias InstaClone.Accounts.{User, UserToken, UserNotifier}
  alias InstaClone.Accounts.Follower

  ## Database getters

  def get_user_by_email(email) when is_binary(email) do
    Repo.get_by(User, email: email)
  end

  def get_user_by_username(username) when is_binary(username) do
    Repo.get_by(User, username: username)
  end

  # Added the bang (!) version because your mount function uses it
  def get_user_by_username!(username) do
    Repo.get_by!(User, username: username)
  end

  def get_user_by_email_and_password(email, password)
      when is_binary(email) and is_binary(password) do
    user = Repo.get_by(User, email: email)
    if User.valid_password?(user, password), do: user
  end

  def get_user!(id), do: Repo.get!(User, id)

  ## User registration

  def register_user(attrs) do
    %User{}
    |> User.registration_changeset(attrs)
    |> Repo.insert()
  end

  def change_user_registration(%User{} = user, attrs \\ %{}) do
    User.registration_changeset(user, attrs)
  end

  ## Settings & Sudo Mode

  def sudo_mode?(user, minutes \\ -20)
  def sudo_mode?(%User{authenticated_at: ts}, minutes) when is_struct(ts, DateTime) do
    DateTime.after?(ts, DateTime.utc_now() |> DateTime.add(minutes, :minute))
  end
  def sudo_mode?(_user, _minutes), do: false

  def change_user_email(user, attrs \\ %{}, opts \\ []) do
    User.email_changeset(user, attrs, opts)
  end

  def update_user_email(user, token) do
    context = "change:#{user.email}"

    Repo.transact(fn ->
      with {:ok, query} <- UserToken.verify_change_email_token_query(token, context),
           %UserToken{sent_to: email} <- Repo.one(query),
           {:ok, user} <- Repo.update(User.email_changeset(user, %{email: email})),
           {_count, _result} <-
             Repo.delete_all(from(UserToken, where: [user_id: ^user.id, context: ^context])) do
        {:ok, user}
      else
        _ -> {:error, :transaction_aborted}
      end
    end)
  end

  def change_user_password(user, attrs \\ %{}, opts \\ []) do
    User.password_changeset(user, attrs, opts)
  end

  def update_user_password(user, attrs) do
    user
    |> User.password_changeset(attrs)
    |> update_user_and_delete_all_tokens()
  end

  ## Session

  def generate_user_session_token(user) do
    {token, user_token} = UserToken.build_session_token(user)
    Repo.insert!(user_token)
    token
  end

  def get_user_by_session_token(token) do
    {:ok, query} = UserToken.verify_session_token_query(token)
    Repo.one(query)
  end

  def delete_user_session_token(token) do
    Repo.delete_all(from(UserToken, where: [token: ^token, context: "session"]))
    :ok
  end

  ## Magic Link & Confirmation

  def get_user_by_magic_link_token(token) do
    with {:ok, query} <- UserToken.verify_magic_link_token_query(token),
         {user, _token} <- Repo.one(query) do
      user
    else
      _ -> nil
    end
  end

  def login_user_by_magic_link(token) do
    {:ok, query} = UserToken.verify_magic_link_token_query(token)

    case Repo.one(query) do
      {%User{confirmed_at: nil, hashed_password: hash}, _token} when not is_nil(hash) ->
        {:error, :confirmation_needed}

      {%User{confirmed_at: nil} = user, _token} ->
        user
        |> User.confirm_changeset()
        |> update_user_and_delete_all_tokens()

      {user, token} ->
        Repo.delete!(token)
        {:ok, {user, []}}

      nil ->
        {:error, :not_found}
    end
  end

  def deliver_user_confirmation_instructions(%User{} = user, confirmation_url_fun)
      when is_function(confirmation_url_fun, 1) do
    if user.confirmed_at do
      {:error, :already_confirmed}
    else
      {encoded_token, user_token} = UserToken.build_email_token(user, "confirm")
      Repo.insert!(user_token)
      UserNotifier.deliver_confirmation_instructions(user, confirmation_url_fun.(encoded_token))
    end
  end

  def deliver_user_update_email_instructions(%User{} = user, current_email, update_email_url_fun)
      when is_function(update_email_url_fun, 1) do
    {encoded_token, user_token} = UserToken.build_email_token(user, "change:#{current_email}")
    Repo.insert!(user_token)
    UserNotifier.deliver_update_email_instructions(user, update_email_url_fun.(encoded_token))
  end

  def deliver_login_instructions(%User{} = user, magic_link_url_fun)
      when is_function(magic_link_url_fun, 1) do
    {encoded_token, user_token} = UserToken.build_email_token(user, "login")
    Repo.insert!(user_token)
    UserNotifier.deliver_login_instructions(user, magic_link_url_fun.(encoded_token))
  end

  # ===================================================================
  # FOLLOWERS LOGIC (The Fixed Section)
  # ===================================================================

  # 1. Action: Follow a user
  # Accepts User structs OR IDs
  def follow_user(%User{} = follower, %User{} = followed), do: follow_user(follower.id, followed.id)
  def follow_user(follower_id, followed_id) do
    %Follower{}
    |> Follower.changeset(%{follower_id: follower_id, followed_id: followed_id})
    |> Repo.insert()
  end

  # 2. Action: Unfollow a user
  def unfollow_user(%User{} = follower, %User{} = followed), do: unfollow_user(follower.id, followed.id)
  def unfollow_user(follower_id, followed_id) do
    from(f in Follower,
      where: f.follower_id == ^follower_id and f.followed_id == ^followed_id
    )
    |> Repo.delete_all()
  end

  # 3. Check: Are we following them?
  def following?(%User{} = follower, %User{} = followed), do: following?(follower.id, followed.id)
  def following?(follower_id, followed_id) do
    Repo.exists?(
      from f in Follower,
      where: f.follower_id == ^follower_id and f.followed_id == ^followed_id
    )
  end

  # 4. Stats: Count Followers
  # Handles Structs or IDs so your LiveView never crashes
  def count_followers(%User{id: id}), do: count_followers(id)
  def count_followers(user_id) do
    Repo.one(
      from f in Follower,
      where: f.followed_id == ^user_id,
      select: count(f.id)
    )
  end

  # 5. Stats: Count Following
  def count_following(%User{id: id}), do: count_following(id)
  def count_following(user_id) do
    Repo.one(
      from f in Follower,
      where: f.follower_id == ^user_id,
      select: count(f.id)
    )
  end

  # 6. List: Get the actual people (Optional, but good to have)
  def get_followers(user_id) do
    from(u in User,
      join: f in Follower, on: f.follower_id == u.id,
      where: f.followed_id == ^user_id
    )
    |> Repo.all()
  end

  def get_following(user_id) do
    from(u in User,
      join: f in Follower, on: f.followed_id == u.id,
      where: f.follower_id == ^user_id
    )
    |> Repo.all()
  end

  ## Token helper

  defp update_user_and_delete_all_tokens(changeset) do
    Repo.transact(fn ->
      with {:ok, user} <- Repo.update(changeset) do
        tokens_to_expire = Repo.all_by(UserToken, user_id: user.id)
        Repo.delete_all(from(t in UserToken, where: t.id in ^Enum.map(tokens_to_expire, & &1.id)))
        {:ok, {user, tokens_to_expire}}
      end
    end)
  end
end
