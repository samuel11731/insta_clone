defmodule InstaClone.Repo.Migrations.CreateComments do
  use Ecto.Migration

 def change do
    create table(:comments, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :body, :text, null: false

      add :user_id, references(:users, type: :binary_id, on_delete: :delete_all)

      add :post_id, references(:posts, type: :binary_id, on_delete: :delete_all)

      add :parent_id, references(:comments, type: :binary_id, on_delete: :delete_all)
      timestamps()
    end

    create index(:comments, [:post_id])
    create index(:comments, [:user_id])
    create index(:comments, [:parent_id])
  end
end
