defmodule InstaClone.Repo.Migrations.CreateCommentLikes do
  use Ecto.Migration

  def change do

    create table(:comment_likes, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :user_id, references(:users, on_delete: :delete_all, type: :binary_id), null: false
      add :comment_id, references(:comments, on_delete: :delete_all, type: :binary_id), null: false
      timestamps(type: :utc_datetime)
    end
    create unique_index(:comment_likes, [:user_id, :comment_id])
    create index(:comment_likes, [:comment_id])
  end
end

