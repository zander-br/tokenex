defmodule Tokenex.Config do
  @moduledoc """
  The Config struct validates and encapsulates Tokenex instance state.

  Typically, you won't use the Config module directly. Tokenex automatically creates
  a Config struct on initialization and passes it through to all supervised children
  with the `:cong` key.
  """

  alias Tokenex.Validation
  alias __MODULE__

  defstruct name: Tokenex, adapters: []

  @type t :: %Config{
          name: String.t(),
          adapters: [module() | {module() | Keyword.t()}]
        }

  @type option :: {:adapters, [module() | {module() | Keyword.t()}]}

  @doc """
  Generate a Config struct after normalizing and verifying Tokenex options.
  """
  @spec new([option()]) :: t()
  def new(opts) when is_list(opts) do
    Validation.validate!(opts, &validate/1)
    struct!(Config, opts)
  end

  @doc """
  Verify configuration options.

  This helper is used by `new/1`, and therefore by `Tokenex.start_link/1`, to verify configuration
  options when an Tokenex supervisor starts.
  """
  def validate(opts) when is_list(opts),
    do: Validation.validate(opts, &validate_opt/1)

  defp validate_opt({:adapters, adapters}),
    do: Validation.validate(adapters, &validate_adapter/1)

  defp validate_adapter(adapter) when not is_tuple(adapter),
    do: validate_adapter({adapter, []})

  defp validate_adapter({adapter, opts}) do
    name = inspect(adapter)

    cond do
      not is_atom(adapter) ->
        {:error, "adapter #{name} is not a valid module"}

      not Code.ensure_loaded?(adapter) ->
        {:error, "adapter #{name} could not be loaded"}

      not function_exported?(adapter, :refresh_token, 0) ->
        {:error, "adapter #{name} is invalid because it's missing an `refresh_token/0` function"}

      not Keyword.keyword?(opts) ->
        {:error, "expected #{name} options to be a keyword list, got: #{inspect(opts)}"}

      true ->
        :ok
    end
  end
end
