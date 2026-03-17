defmodule InstaClone.Repo.Migrations.AddFieldsToUsers do
  use Ecto.Migration

  def change do
alter table(:users) do
add :username, :string ,null: false
add :full_name, :string
end
  end
end
