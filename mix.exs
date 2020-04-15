defmodule AuthPlug.MixProject do
  use Mix.Project

  def project do
    [
      app: :auth_plug,
      version: "0.1.1",
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: package(),
      description: "Turnkey Auth Plug.",
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
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
      # JWT sign/verify: github.com/joken-elixir/joken
      {:joken, "~> 2.2"},
      # Plug helper functions: github.com/elixir-plug/plug
      {:plug, "~> 1.10"},
      # Phoenix for defining sessions (don't worry it gets deduped):
      {:phoenix, "~> 1.4.16"},
      # Track coverage: github.com/parroty/excoveralls
      {:excoveralls, "~> 0.12.3", only: :test},
      # For publishing Hex.docs:
      {:ex_doc, "~> 0.21.3", only: :dev}
    ]
  end

  defp package() do
    [
      files: ~w(lib LICENSE mix.exs README.md),
      name: "auth_plug",
      licenses: ["GNU GPL v2.0"],
      maintainers: ["dwyl"],
      links: %{"GitHub" => "https://github.com/dwyl/auth_plug"}
    ]
  end
end
