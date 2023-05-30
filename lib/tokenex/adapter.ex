defmodule Tokenex.Adapter do
  @moduledoc """
  An Adapter defines the behavior that will be used to obtain an access token
  to be cached. It also provides the function `get_access_token/0`
  which will get the cached access token.
  """

  alias Tokenex.Token

  @callback refresh_token() :: {:ok, token :: Token.t()} | {:error, reason :: any()}

  defmacro __using__(_opts) do
    quote location: :keep do
      @behaviour Tokenex.Adapter

      alias Tokenex.Cache

      @doc ~s"""
      Returns the cached access token for the provider `#{__MODULE__}`

        ## Example

          iex> #{__MODULE__}.get_access_token()
          {:ok, "access_token"}

          iex> #{__MODULE__}.get_access_token()
          {:error, :provider_error}
      """
      @spec get_access_token() :: {:ok, access_token :: String.t()} | {:error, reason :: any()}
      def get_access_token(),
        do: Cache.get_access_token(__MODULE__)
    end
  end
end
