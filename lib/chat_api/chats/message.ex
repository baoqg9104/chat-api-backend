defmodule ChatApi.Chats.Message do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "messages" do
    field :status, :string
    field :content, :string
    field :sender_id, :binary_id
    field :receiver_id, :binary_id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(message, attrs) do
    message
    |> cast(attrs, [:content, :status, :sender_id, :receiver_id])
    |> validate_required([:content, :status, :sender_id, :receiver_id])
  end
end
