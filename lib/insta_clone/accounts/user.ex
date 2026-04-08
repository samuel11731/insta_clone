defmodule InstaClone.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset

  # 1. We defined the schema (the database structure)
  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "users" do
    field :email, :string
    # Added
    field :username, :string
    # Added
    field :bio, :string
    # Added
    field :avatar_path, :string
    # Added
    field :full_name, :string
    field :password, :string, virtual: true, redact: true
    field :hashed_password, :string, redact: true
    field :confirmed_at, :utc_datetime
    field :authenticated_at, :utc_datetime, virtual: true
    has_many :posts, InstaClone.Timeline.Post
    has_many :follower_relationships, InstaClone.Accounts.Follower, foreign_key: :followed_id
    has_many :followers, through: [:follower_relationships, :follower]

    has_many :following_relationships, InstaClone.Accounts.Follower, foreign_key: :follower_id
    has_many :following, through: [:following_relationships, :followed]

    timestamps(type: :utc_datetime)
  end

  def registration_changeset(user, attrs, opts \\ []) do
    attrs = maybe_put_username(attrs)

    user
    |> cast(attrs, [:email, :password, :username, :full_name])
    |> validate_email(opts)
    |> validate_password(opts)
    |> validate_required([:username])
    |> validate_length(:username, min: 3, max: 30)
    |> validate_format(:username, ~r/^[a-z0-9_]+$/,
      message: "only letters, numbers, and underscores"
    )
    |> unsafe_validate_unique(:username, InstaClone.Repo)
    |> unique_constraint(:username)
  end

  defp maybe_put_username(attrs) do
    # Only generate if missing or empty
    if Map.get(attrs, "username") || Map.get(attrs, :username) do
      attrs
    else
      base =
        (Map.get(attrs, "full_name") || Map.get(attrs, :full_name) || Map.get(attrs, "email") ||
           Map.get(attrs, :email) || "user")
        |> String.split("@")
        |> List.first()
        |> String.downcase()
        |> String.replace(~r/[^a-z0-9_]/, "")

      random_suffix = :crypto.strong_rand_bytes(2) |> Base.encode16(case: :lower)

      username =
        if String.length(base) < 3,
          do: "user_#{random_suffix}",
          else: "#{String.slice(base, 0..15)}_#{random_suffix}"

      if is_map_key(attrs, "email"),
        do: Map.put(attrs, "username", username),
        else: Map.put(attrs, :username, username)
    end
  end

  def profile_changeset(user, attrs) do
    user
    |> cast(attrs, [:username, :full_name, :bio, :avatar_path])
    |> validate_required([:username, :full_name])
    |> validate_length(:username, min: 3, max: 30)
    |> validate_format(:username, ~r/^[a-z0-9_]+$/,
      message: "only letters, numbers, and underscores"
    )
    |> unsafe_validate_unique(:username, InstaClone.Repo)
    |> unique_constraint(:username)
  end

  def email_changeset(user, attrs, opts \\ []) do
    user
    |> cast(attrs, [:email])
    |> validate_email(opts)
    |> case do
      %{changes: %{email: _}} = changeset -> changeset
      %{} = changeset -> add_error(changeset, :email, "did not change")
    end
  end

  def password_changeset(user, attrs, opts \\ []) do
    user
    |> cast(attrs, [:password])
    |> validate_confirmation(:password, message: "does not match password")
    |> validate_password(opts)
  end

  defp validate_email(changeset, opts) do
    changeset
    |> validate_required([:email])
    |> validate_format(:email, ~r/^[^@,;\s]+@[^@,;\s]+$/,
      message: "must have the @ sign and no spaces"
    )
    |> validate_length(:email, max: 160)
    |> maybe_validate_unique_email(opts)
  end

  defp maybe_validate_unique_email(changeset, opts) do
    if Keyword.get(opts, :validate_unique, true) do
      changeset
      |> unsafe_validate_unique(:email, InstaClone.Repo)
      |> unique_constraint(:email)
    else
      changeset
    end
  end

  defp validate_password(changeset, opts) do
    changeset
    |> validate_required([:password])
    |> validate_length(:password, min: 8, max: 24)
    |> maybe_hash_password(opts)
  end

  defp maybe_hash_password(changeset, opts) do
    hash_password? = Keyword.get(opts, :hash_password, true)
    password = get_change(changeset, :password)

    if hash_password? && password && changeset.valid? do
      changeset
      |> validate_length(:password, max: 72, count: :bytes)
      |> put_change(:hashed_password, Bcrypt.hash_pwd_salt(password))
      |> delete_change(:password)
    else
      changeset
    end
  end

  def confirm_changeset(user) do
    now = DateTime.utc_now(:second)
    change(user, confirmed_at: now)
  end

  def valid_password?(%InstaClone.Accounts.User{hashed_password: hashed_password}, password)
      when is_binary(hashed_password) and byte_size(password) > 0 do
    Bcrypt.verify_pass(password, hashed_password)
  end

  def valid_password?(_, _) do
    Bcrypt.no_user_verify()
    false
  end
end
