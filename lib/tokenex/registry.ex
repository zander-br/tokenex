defmodule Tokenex.Registry do
  @moduledoc """
  Local process storage for Tokenex instances
  """

  @doc false
  def child_spec(_arg) do
    [keys: :unique, name: __MODULE__]
    |> Registry.child_spec()
    |> Supervisor.child_spec(id: __MODULE__)
  end

  @doc """
  Build a via tuple suitable for calls to a supervised Tokenex process.

  ## Example

  For a supervised module:

    Tokenex.Registry.via(CustomAdapter)
  """
  def via(name), do: {:via, Registry, {__MODULE__, name}}
end
