defmodule InstaClone.Repo.Migrations.CreateLikes do
  use Ecto.Migration
  def change do

    create table(:likes, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :user_id, references(:users, type: :binary_id, on_delete: :delete_all)
      add :post_id, references(:posts, type: :binary_id, on_delete: :delete_all)
      timestamps()
    end

    create unique_index(:likes, [:user_id, :post_id])
  end
end
