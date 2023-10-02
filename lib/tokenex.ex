defmodule Tokenex do
  use Supervisor

  alias Tokenex.{Cache, Config, Registry}
  alias __MODULE__

  @type option :: {:adapters, [module() | {module() | Keyword.t()}]}

  def start_link(_opts) do
    opts = Application.get_all_env(:tokenex)
    config = Config.new(opts)
    Supervisor.start_link(Tokenex, config, name: Tokenex)
  end

  @impl Supervisor
  def init(%Config{adapters: adapters}) do
    children = Enum.map(adapters, &adapter_child_spec/1)
    Supervisor.init(children, strategy: :one_for_one)
  end

  defp adapter_child_spec({adapter, opts}) do
    name = Registry.via(adapter)
    opts = Keyword.merge(opts, adapter: adapter, name: name)
    Supervisor.child_spec({Cache, opts}, id: adapter)
  end

  defp adapter_child_spec(adapter) do
    name = Registry.via(adapter)
    opts = [{:adapter, adapter}, {:name, name}]
    Supervisor.child_spec({Cache, opts}, id: adapter)
  end
end
