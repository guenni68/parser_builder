defmodule ParserBuilder.MixProject do
  use Mix.Project

  @version "1.4.0"
  @url "https://github.com/guenni68/parser_builder.git"

  def project do
    [
      app: :parser_builder,
      version: @version,
      elixir: "~> 1.12",
      name: "ParserBuilder",
      description: "Easily create resumable parsers with parser_builder",
      start_permanent: Mix.env() == :prod,
      elixirc_paths: elixirc_paths(Mix.env()),
      deps: deps(),
      package: package(),
      docs: [
        api_reference: false,
        main: "ParserBuilder",
        extras: ["README.md", "CHANGELOG.md"]
      ]
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

  defp package() do
    %{
      licenses: ["Apache-2.0"],
      maintainers: ["Guenther Schmidt"],
      links: %{"GitHub" => @url}
    }
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:erlsom, "~> 1.5"},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false}
    ]
  end
end
