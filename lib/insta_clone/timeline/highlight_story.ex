defmodule InstaClone.Timeline.HighlightStory do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  schema "highlight_stories" do
    belongs_to :highlight, InstaClone.Timeline.Highlight, primary_key: true
    belongs_to :story, InstaClone.Timeline.Story, primary_key: true
  end

  @doc false
  def changeset(highlight_story, attrs) do
    highlight_story
    |> cast(attrs, [:highlight_id, :story_id])
    |> validate_required([:highlight_id, :story_id])
  end
end
