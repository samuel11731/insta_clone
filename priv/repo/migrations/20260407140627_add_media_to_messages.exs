defmodule InstaClone.Repo.Migrations.AddMediaToMessages do
  use Ecto.Migration

  def change do
    alter table(:messages) do
      add :media_url, :string
      add :media_type, :string, default: "text"
      add :media_duration, :integer
      modify :content, :text, null: true
    end
  end
end
