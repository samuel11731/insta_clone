defmodule InstaClone.Repo.Migrations.CreateFollowers do
  use Ecto.Migration

  def change do
    create table(:followers, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :follower_id, references(:users, on_delete: :delete_all, type: :binary_id)

      add :followed_id, references(:users, on_delete: :delete_all, type: :binary_id)

      timestamps(type: :utc_datetime)
    end

    create index(:followers, [:follower_id])
    create index(:followers, [:followed_id])

    create unique_index(:followers, [:follower_id, :followed_id])
  end
end
