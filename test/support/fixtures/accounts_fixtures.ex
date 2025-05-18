defmodule ChatApi.AccountsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `ChatApi.Accounts` context.
  """

  @doc """
  Generate a user.
  """
  def user_fixture(attrs \\ %{}) do
    {:ok, user} =
      attrs
      |> Enum.into(%{
        email: "some email",
        hashed_password: "some hashed_password",
        status: "some status",
        username: "some username"
      })
      |> ChatApi.Accounts.create_user()

    user
  end
end
