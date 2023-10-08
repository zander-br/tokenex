defmodule Tokenex.Token do
  @moduledoc """
  The Token struct validates and encapsulates token state

  The public fields are:

    * `access_token - Stores a string containing the access_token`
    * `errors       - All errors from validations`
    * `expires_in   - Stores token expiration time`
    * `token_type   - Stores the token type`
    * `valid?       - Stores if the struct is valid`

  """
  alias __MODULE__

  defstruct access_token: nil,
            errors: [],
            expires_in: nil,
            expires_timestamp: nil,
            token_type: nil,
            valid?: false

  @type t :: %Token{
          access_token: String.t(),
          errors: list(),
          expires_timestamp: non_neg_integer(),
          expires_in: non_neg_integer(),
          token_type: String.t(),
          valid?: boolean()
        }

  @required_field ~w(access_token expires_in token_type)a
  @allowed_token_types ~w(bearer)
  @types %{access_token: :string, expires_in: :integer, token_type: :string}

  @doc ~S"""
  Applies the given `attrs` and returns a `Tokenex.Token` struct.

  All attributes provided via a string key map or an atom key map are
  converted and will have their key name converted to an atom

  ## Examples

    iex> Tokenex.Token.new(%{access_token: "access_token", expires_in: 1200, token_type: "bearer"})
    %Tokenex.Token{access_token: "access_token", errors: [], expires_timestamp: nil, expires_in: 1200, token_type: "bearer", valid?: true}

  """
  @spec new(attrs :: map()) :: t()
  def new(attrs) do
    attrs
    |> cast()
    |> validate_required()
    |> validate_expires_in()
    |> validate_token_type()
  end

  defp cast(attrs) do
    attrs = convert_attrs(attrs)
    keys = Map.keys(@types)
    token = %Token{valid?: true, errors: []}
    Enum.reduce(keys, token, &process_attrs(&1, attrs, &2))
  end

  defp validate_required(%Token{valid?: true} = token) do
    fields_with_errors = for field <- @required_field, missing?(token, field), do: field

    case fields_with_errors do
      [] ->
        token

      _ ->
        message = "can't be blank"
        errors = Enum.map(fields_with_errors, &{&1, {message, [validation: :required]}})

        token =
          Enum.reduce(fields_with_errors, token, fn field, acc ->
            Map.put(acc, field, nil)
          end)

        %Token{token | errors: errors, valid?: false}
    end
  end

  defp validate_required(token), do: token

  defp validate_expires_in(%Token{errors: errors, expires_in: expires_in} = token)
       when not is_nil(expires_in) and expires_in <= 0 do
    message = "expires_in must be greater than 0"
    new_errors = [{:expires_in, {message, [validation: :number]}} | errors]
    %Token{token | expires_in: nil, errors: new_errors, valid?: false}
  end

  defp validate_expires_in(token), do: token

  defp validate_token_type(%Token{errors: errors, token_type: token_type} = token)
       when not is_nil(token_type) and token_type not in @allowed_token_types do
    valid_options = Enum.join(@allowed_token_types, ", ")
    message = "invalid token_type should be (#{valid_options})"
    new_errors = [{:token_type, {message, [validation: :inclusion]}} | errors]
    %Token{token | token_type: nil, errors: new_errors, valid?: false}
  end

  defp validate_token_type(token), do: token

  defp convert_attrs(attrs) do
    case :maps.next(:maps.iterator(attrs)) do
      {key, _, _} when is_atom(key) ->
        for {key, value} <- attrs, into: %{} do
          {Atom.to_string(key), value}
        end

      _ ->
        attrs
    end
  end

  defp process_attrs(key, attrs, %Token{errors: errors} = token) do
    {key, attrs_key} = cast_key(key)
    type = @types[key]

    case cast_field(attrs_key, type, attrs) do
      {:ok, value} ->
        Map.put(token, key, value)

      {:invalid, reason} ->
        token
        |> Map.put(:errors, [{key, {reason, [type: type, validation: :cast]}} | errors])
        |> Map.put(:valid?, false)

      :missing ->
        token
    end
  end

  defp cast_key(key), do: {key, Atom.to_string(key)}

  defp cast_field(attrs_key, type, attrs) do
    case attrs do
      %{^attrs_key => value} ->
        case cast_value(value, type) do
          {:ok, value} -> {:ok, value}
          {:error, error} -> {:invalid, error}
        end

      _ ->
        :missing
    end
  end

  defp cast_value(value, :string) when is_binary(value), do: {:ok, value}
  defp cast_value(_value, :string), do: {:error, "is invalid string"}
  defp cast_value(value, :integer) when is_integer(value), do: {:ok, value}
  defp cast_value(_value, :integer), do: {:error, "is invalid integer"}

  defp missing?(token, field) do
    case Map.get(token, field) do
      value when is_binary(value) -> String.trim(value) == ""
      nil -> true
      _ -> false
    end
  end
end
