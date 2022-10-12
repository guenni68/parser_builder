defmodule ParserBuilder.MixProject do
  use Mix.Project

  @version "1.0.0"
  @url "https://github.com/guenni68/parser_builder.git"

  def project do
    [
      app: :parser_builder,
      version: @version,
      elixir: "~> 1.12",
      name: "ParserBuilder",
      description: "A parser library that allows you to build your parser in XML",
      start_permanent: Mix.env() == :prod,
      elixirc_paths: elixirc_paths(Mix.env()),
      deps: deps(),
      package: package()
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
      {:erlsom, "~> 1.5"}
    ]
  end
end
