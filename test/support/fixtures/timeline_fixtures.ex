defmodule InstaClone.TimelineFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `InstaClone.Timeline` context.
  """

  @doc """
  Generate a post.
  """
  def post_fixture(scope, attrs \\ %{}) do
    attrs =
      Enum.into(attrs, %{
        caption: "some caption",
        image_path: "some image_path",
        user_id: "7488a646-e31f-11e4-aace-600308960662"
      })

    {:ok, post} = InstaClone.Timeline.create_post(scope, attrs)
    post
  end
end
