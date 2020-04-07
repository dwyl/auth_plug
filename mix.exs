defmodule AuthPlug.MixProject do
  use Mix.Project

  def project do
    [
      app: :auth_plug,
      version: "0.1.0",
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: package(),
      description: description(),
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

      {:plug_cowboy, "~> 2.1", only: :test},
      {:excoveralls, "~> 0.12.3", only: :test},
      {:ex_doc, "~> 0.21.3", only: :dev}
    ]
  end

  defp description() do
    "A plug that handles all your authentication needs."
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
