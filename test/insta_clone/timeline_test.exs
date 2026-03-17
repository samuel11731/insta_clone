defmodule InstaClone.TimelineTest do
  use InstaClone.DataCase

  alias InstaClone.Timeline

  describe "posts" do
    alias InstaClone.Timeline.Post

    import InstaClone.AccountsFixtures, only: [user_scope_fixture: 0]
    import InstaClone.TimelineFixtures

    @invalid_attrs %{user_id: nil, caption: nil, image_path: nil}

    test "list_posts/1 returns all scoped posts" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      post = post_fixture(scope)
      other_post = post_fixture(other_scope)
      assert Timeline.list_posts(scope) == [post]
      assert Timeline.list_posts(other_scope) == [other_post]
    end

    test "get_post!/2 returns the post with given id" do
      scope = user_scope_fixture()
      post = post_fixture(scope)
      other_scope = user_scope_fixture()
      assert Timeline.get_post!(scope, post.id) == post
      assert_raise Ecto.NoResultsError, fn -> Timeline.get_post!(other_scope, post.id) end
    end

    test "create_post/2 with valid data creates a post" do
      valid_attrs = %{user_id: "7488a646-e31f-11e4-aace-600308960662", caption: "some caption", image_path: "some image_path"}
      scope = user_scope_fixture()

      assert {:ok, %Post{} = post} = Timeline.create_post(scope, valid_attrs)
      assert post.user_id == "7488a646-e31f-11e4-aace-600308960662"
      assert post.caption == "some caption"
      assert post.image_path == "some image_path"
      assert post.user_id == scope.user.id
    end

    test "create_post/2 with invalid data returns error changeset" do
      scope = user_scope_fixture()
      assert {:error, %Ecto.Changeset{}} = Timeline.create_post(scope, @invalid_attrs)
    end

    test "update_post/3 with valid data updates the post" do
      scope = user_scope_fixture()
      post = post_fixture(scope)
      update_attrs = %{user_id: "7488a646-e31f-11e4-aace-600308960668", caption: "some updated caption", image_path: "some updated image_path"}

      assert {:ok, %Post{} = post} = Timeline.update_post(scope, post, update_attrs)
      assert post.user_id == "7488a646-e31f-11e4-aace-600308960668"
      assert post.caption == "some updated caption"
      assert post.image_path == "some updated image_path"
    end

    test "update_post/3 with invalid scope raises" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      post = post_fixture(scope)

      assert_raise MatchError, fn ->
        Timeline.update_post(other_scope, post, %{})
      end
    end

    test "update_post/3 with invalid data returns error changeset" do
      scope = user_scope_fixture()
      post = post_fixture(scope)
      assert {:error, %Ecto.Changeset{}} = Timeline.update_post(scope, post, @invalid_attrs)
      assert post == Timeline.get_post!(scope, post.id)
    end

    test "delete_post/2 deletes the post" do
      scope = user_scope_fixture()
      post = post_fixture(scope)
      assert {:ok, %Post{}} = Timeline.delete_post(scope, post)
      assert_raise Ecto.NoResultsError, fn -> Timeline.get_post!(scope, post.id) end
    end

    test "delete_post/2 with invalid scope raises" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      post = post_fixture(scope)
      assert_raise MatchError, fn -> Timeline.delete_post(other_scope, post) end
    end

    test "change_post/2 returns a post changeset" do
      scope = user_scope_fixture()
      post = post_fixture(scope)
      assert %Ecto.Changeset{} = Timeline.change_post(scope, post)
    end
  end
end
