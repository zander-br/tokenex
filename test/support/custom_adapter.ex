defmodule CustomAdapter do
  use Tokenex.Adapter

  alias Tokenex.Token

  @impl true
  def refresh_token() do
    token = Token.new(%{access_token: "access_token", expires_in: 1200, token_type: "bearer"})
    {:ok, token}
  end
end
