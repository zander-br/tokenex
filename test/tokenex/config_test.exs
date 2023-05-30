defmodule Tokenex.ConfigTest do
  use ExUnit.Case, async: true

  alias CustomAdapter
  alias Tokenex.Config

  describe "new/1" do
    test "should return %Config when provided a valid opts" do
      opts = [{:adapters, [{CustomAdapter, auto: true}]}]
      assert %Config{name: Tokenex, adapters: [{CustomAdapter, [auto: true]}]} == Config.new(opts)
    end

    test "should return a raise when provided an invalid opts" do
      invalid_opts = [{:adapters, [Adapter]}]
      reason = "adapter Adapter could not be loaded"
      assert_raise ArgumentError, reason, fn -> Config.new(invalid_opts) end
    end
  end

  describe "validate/1" do
    test "should return :ok when provided a valid adapter" do
      opts = [{:adapters, [{CustomAdapter, auto: true}]}]
      assert :ok == Config.validate(opts)
    end

    test "should return {:error, reason} when the provided adapter is not a module" do
      invalid_opts = [{:adapters, ["Adapter"]}]
      reason = "adapter \"Adapter\" is not a valid module"
      assert {:error, reason} == Config.validate(invalid_opts)
    end

    test "should return {:error, reason} when unable to load the provided adapter" do
      invalid_opts = [{:adapters, [Adapter]}]
      reason = "adapter Adapter could not be loaded"
      assert {:error, reason} == Config.validate(invalid_opts)
    end

    test "should return {:error, reason} when the provided module does not implement the function refresh_token/0" do
      invalid_opts = [{:adapters, [Enum]}]
      reason = "adapter Enum is invalid because it's missing an `refresh_token/0` function"
      assert {:error, reason} == Config.validate(invalid_opts)
    end

    test "should return {:error, reason} when the provided adapter opts is not a keyword list" do
      invalid_opts = [{:adapters, [{CustomAdapter, :invalid_options}]}]
      reason = "expected CustomAdapter options to be a keyword list, got: :invalid_options"
      assert {:error, reason} == Config.validate(invalid_opts)
    end
  end
end
