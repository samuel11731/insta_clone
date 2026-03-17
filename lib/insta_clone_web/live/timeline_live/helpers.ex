defmodule InstaCloneWeb.TimelineLive.Helpers do
  @moduledoc """
  Helper functions for the Timeline LiveView
  """

  @doc """
  Counts the number of replies (child comments) for a given parent comment.
  """
  def count_replies(comments, parent_id) do
    Enum.count(comments, fn comment -> comment.parent_id == parent_id end)
  end

  @doc """
  Groups comments into top-level and replies
  """
  def group_comments(comments) do
    top_level = Enum.filter(comments, fn c -> is_nil(c.parent_id) end)
    {top_level, comments}
  end
end
