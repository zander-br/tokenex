defmodule Tokenex.MixProject do
  use Mix.Project

  @version "1.0.0"

  def project do
    [
      app: :tokenex,
      version: @version,
      elixir: "~> 1.14",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test,
        "test.ci": :test
      ],

      # Dialyzer
      dialyzer: [
        plt_add_apps: [:ex_unit],
        plt_core_path: "_build/#{Mix.env()}",
        flags: [:error_handling, :missing_return, :underspecs]
      ]
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {Tokenex.Application, []}
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.3", only: [:test, :dev], runtime: false},
      {:excoveralls, "~> 0.10", only: :test},
      {:ex_machina, "~> 2.7.0", only: :test}
    ]
  end

  defp aliases do
    [
      "test.ci": [
        "format --check-formatted",
        "deps.unlock --check-unused",
        "credo --strict",
        "test --raise",
        "dialyzer"
      ]
    ]
  end
end
