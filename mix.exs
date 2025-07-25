defmodule ReqHammer.MixProject do
  use Mix.Project

  def project do
    [
      app: :req_hammer,
      version: "0.1.0",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      elixirc_paths: elixirc_paths(Mix.env())
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:req, "~> 0.5 or ~> 1.0"},
      {:hammer, "~> 7.0"},
      {:plug, "~> 1.0", only: :test}
    ]
  end
end
