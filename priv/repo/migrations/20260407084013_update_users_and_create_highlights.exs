defmodule InstaClone.Repo.Migrations.UpdateUsersAndCreateHighlights do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :bio, :text
      add :avatar_path, :string
    end

    create table(:highlights, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :user_id, references(:users, on_delete: :delete_all, type: :binary_id)
      add :title, :string
      add :cover_path, :string

      timestamps(type: :utc_datetime)
    end

    create index(:highlights, [:user_id])

    create table(:highlight_stories, primary_key: false) do
      add :highlight_id, references(:highlights, on_delete: :delete_all, type: :binary_id)
      add :story_id, references(:stories, on_delete: :delete_all, type: :binary_id)
    end

    create index(:highlight_stories, [:highlight_id])
    create index(:highlight_stories, [:story_id])
    create unique_index(:highlight_stories, [:highlight_id, :story_id])
  end
end
