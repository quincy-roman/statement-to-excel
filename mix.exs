defmodule StatementToExcel.MixProject do
  use Mix.Project

  def project do
    [
      app: :statement_to_excel,
      version: "0.1.0",
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      deps: deps()
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
      {:elixlsx, "~> 0.5.1"}
    ]
  end
end
