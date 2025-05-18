defmodule ChatApi.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "users" do
    field :status, :string
    field :username, :string
    field :email, :string
    field :hashed_password, :string

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:username, :email, :hashed_password, :status])
    |> validate_required([:username, :email, :hashed_password, :status])
    |> unique_constraint(:email)
  end
end
