defmodule InstaClone.Repo.Migrations.CreateNotifications do
  use Ecto.Migration

  def change do
    create table(:notifications, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :type, :string, null: false
      add :is_read, :boolean, default: false, null: false
      add :actor_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false
      add :recipient_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false
      add :post_id, references(:posts, type: :binary_id, on_delete: :delete_all)

      timestamps(type: :utc_datetime)
    end

    create index(:notifications, [:recipient_id])
    create index(:notifications, [:actor_id])
    create index(:notifications, [:post_id])
  end
end
