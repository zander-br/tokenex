defmodule Tokenex.Validation do
  @moduledoc false

  @type validator ::
          ({atom(), term()} ->
             :ok
             | {:unknown, atom() | {atom(), term()}, module()}
             | {:error, term()})

  @doc """
  A utility to help validate options without resorting to `throw` or `raise` for control flow.

  ## Example

  Ensure all keys are known and the correct type:

      iex> Tokenex.Validation.validate([{:name, "Tokenex"}], fn
      ...>   {:conf, conf} when is_struct(conf) -> :ok
      ...>   {:name, name} when is_binary(name) -> :ok
      ...>   opt -> {:error, "unknown option: " <> inspect(opt)}
      ...> end)
      :ok

  """
  @spec validate(opts :: Keyword.t(), validator()) :: :ok | {:error, reason :: String.t()}
  def validate(opts, validator) when is_list(opts) and is_function(validator, 1) do
    Enum.reduce_while(opts, :ok, fn opt, acc ->
      case validator.(opt) do
        :ok -> {:cont, acc}
        {:error, _reason} = error -> {:halt, error}
      end
    end)
  end

  @doc """
  Similar to `validate/2`, but it will raise an `ArgumentError` for any errors.
  """
  @spec validate!(opts :: Keyword.t(), validator()) :: :ok
  def validate!(opts, validator) when is_list(opts) and is_function(validator, 1) do
    with {:error, reason} <- apply(validator, opts), do: raise(ArgumentError, reason)
  end
end
