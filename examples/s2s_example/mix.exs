defmodule BroadwayS2SExample.MixProject do
  use Mix.Project

  def project do
    [
      app: :broadway_s2s_example,
      version: "0.1.0",
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {BroadwayS2SExample.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:broadway_s2s, path: "../.."}
    ]
  end
end
