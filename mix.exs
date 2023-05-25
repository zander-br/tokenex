defmodule Tokenex.MixProject do
  @moduledoc false
  use Mix.Project

  @version "1.0.0"

  def project do
    [
      app: :tokenex,
      version: @version,
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps(),

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

  defp deps do
    [
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.3", only: [:test, :dev], runtime: false}
    ]
  end
end
