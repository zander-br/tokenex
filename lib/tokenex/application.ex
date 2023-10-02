defmodule Tokenex.Application do
  @moduledoc false
  use Application

  @impl true
  def start(_type, _args) do
    children = [Tokenex.Registry]
    opts = [strategy: :one_for_one, name: Tokenex.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
