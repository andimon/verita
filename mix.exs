defmodule Verita.MixProject do
  use Mix.Project

  @github "https://github.com/andimon/verita"
  def project do
    [
      app: :verita,
      version: "0.1.0-beta-beta",
      elixir: "~> 1.15",
      description: description(),
      start_permanent: Mix.env() == :prod,
      package: package(),
      deps: deps(),

      # Documentation
      name: "Verita",
      source_url: @github,
      docs: docs(),

      # Testing
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test,
        "coveralls.json": :test
      ]
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
      # Development and Testing
      {:ex_doc, "~> 0.34", only: :dev, runtime: false, warn_if_outdated: true},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
      {:excoveralls, "~> 0.18", only: :test}

      # Runtime Dependencies
    ]
  end

  defp docs do
    [
      # The main page in the docs
      main: "Verita",
      logo: "priv/img/logo.png",
      extras: ["README.md"]
    ]
  end

  defp description() do
    "Verita is a general purpose authentication library."
  end

  defp package() do
    [
      # This option is only needed when you don't want to use the OTP application name
      name: "verita",
      # These are the default files included in the package
      files: ~w(lib priv .formatter.exs mix.exs README.md LICENSE CHANGELOG.md),
      licenses: ["MIT"],
      links: %{"GitHub" => @github}
    ]
  end
end
