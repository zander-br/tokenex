defmodule Tokenex.ValidationTest do
  use ExUnit.Case, async: true
  doctest Tokenex.Validation

  alias Tokenex.Validation

  describe "validate/2" do
    test "should return :ok when the validation is successful" do
      opts = [{:name, "tokenex"}]
      validator = fn {:name, name} when is_binary(name) -> :ok end
      assert :ok == Validation.validate(opts, validator)
    end

    test "should return {:error, reason} when validation fails" do
      opts = [{:name, "tokenex"}]
      validator = fn _opt -> {:error, "any_reason"} end
      assert {:error, "any_reason"} == Validation.validate(opts, validator)
    end
  end

  describe "validate!/2" do
    test "should return :ok when the validation is successful" do
      opts = [{:name, "tokenex"}]
      validator = fn _ -> :ok end
      assert :ok == Validation.validate!(opts, validator)
    end

    test "should return a raise when validation fails" do
      opts = [{:name, "tokenex"}]
      validator = fn _opt -> {:error, "any_reason"} end
      assert_raise ArgumentError, "any_reason", fn -> Validation.validate!(opts, validator) end
    end
  end
end
