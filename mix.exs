defmodule BroadwayS2s.MixProject do
  use Mix.Project

  @version "0.0.1-pre1"
  @description "A S2S connector for Broadway"

  def project do
    [
      app: :broadway_s2s,
      version: @version,
      description: @description,
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      docs: docs(),
      package: package()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:broadway, "~> 0.6.0"},
      {:nifi_s2s, "~> 0.0.2"},
      {:ex_doc, ">= 0.19.0", only: :dev, runtime: false}
    ]
  end

  defp docs do
    [
      main: "BroadwayS2S.Producer",
      source_ref: "v#{@version}",
      source_url: "https://github.com/joaohf/broadway_s2s"
    ]
  end

  defp package do
    %{
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/joaohf/broadway_s2s"}
    }
  end
end
