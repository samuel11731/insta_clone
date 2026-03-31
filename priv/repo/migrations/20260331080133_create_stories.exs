defmodule InstaClone.Repo.Migrations.CreateStories do
  use Ecto.Migration

  def change do
    create table(:stories) do
      add :media_path, :string, null: false
      add :media_type, :string, null: false # "image" or "video"
      add :expires_at, :utc_datetime, null: false
      add :user_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:stories, [:user_id])
    create index(:stories, [:expires_at])
  end
end
