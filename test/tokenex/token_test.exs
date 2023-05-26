defmodule Tokenex.TokenTest do
  use ExUnit.Case, async: true
  doctest Tokenex.Token

  import Tokenex.Support.Factory

  alias Tokenex.Token

  describe "new/1" do
    test "should return %Token{valid?: true} when provided valid attrs" do
      valid_attrs = build(:token_attrs)

      assert %Token{
               access_token: "access_token",
               errors: [],
               expires_in: 1200,
               token_type: "bearer",
               valid?: true
             } == Token.new(valid_attrs)
    end

    test "should return %Token{valid?: false} when access_token is not provided" do
      invalid_attrs = :token_attrs |> build() |> Map.delete("access_token")
      token = Token.new(invalid_attrs)

      refute token.valid?
      assert %{access_token: "can't be blank"} == errors_on(token)
    end

    test "should return %Token{valid?: false} when expires_in is not provided" do
      invalid_attrs = :token_attrs |> build() |> Map.delete("expires_in")
      token = Token.new(invalid_attrs)

      refute token.valid?
      assert %{expires_in: "can't be blank"} == errors_on(token)
    end

    test "should return %Token{valid?: false} when token_type is not provided" do
      invalid_attrs = :token_attrs |> build() |> Map.delete("token_type")
      token = Token.new(invalid_attrs)

      refute token.valid?
      assert %{token_type: "can't be blank"} == errors_on(token)
    end

    test "should return %Token{valid?: false} when given access_token is of invalid type" do
      invalid_attrs = build(:token_attrs, %{"access_token" => :invalid_type})
      token = Token.new(invalid_attrs)

      refute token.valid?
      assert %{access_token: "is invalid string"} == errors_on(token)
    end

    test "should return %Token{valid?: false} when given expires_in is of invalid type" do
      invalid_attrs = build(:token_attrs, %{"expires_in" => :invalid_type})
      token = Token.new(invalid_attrs)

      refute token.valid?
      assert %{expires_in: "is invalid integer"} == errors_on(token)
    end

    test "should return %Token{valid?: false} when given token_type is of invalid type" do
      invalid_attrs = build(:token_attrs, %{"token_type" => :invalid_type})
      token = Token.new(invalid_attrs)

      refute token.valid?
      assert %{token_type: "is invalid string"} == errors_on(token)
    end

    test "should return %Token{valid?: false} when the given expires_in is less than zero" do
      invalid_attrs = build(:token_attrs, %{"expires_in" => -1})
      token = Token.new(invalid_attrs)

      refute token.valid?
      assert %{expires_in: "expires_in must be greater than 0"} == errors_on(token)
    end

    test "should return %Token{valid?: false} when the given expires_in equals zero" do
      invalid_attrs = build(:token_attrs, %{"expires_in" => 0})
      token = Token.new(invalid_attrs)

      refute token.valid?
      assert %{expires_in: "expires_in must be greater than 0"} == errors_on(token)
    end

    test "should return %Token{valid?: false} when the provided token_type is invalid" do
      invalid_attrs = build(:token_attrs, %{"token_type" => "invalid_type"})
      token = Token.new(invalid_attrs)

      refute token.valid?
      assert %{token_type: "invalid token_type should be (bearer)"} == errors_on(token)
    end
  end

  def errors_on(%Token{errors: errors}) do
    Enum.reduce(errors, %{}, fn error, acc ->
      {key, {message, _opts}} = error
      Map.put(acc, key, message)
    end)
  end
end
