defmodule AuthPlug.MixProject do
  use Mix.Project

  def project do
    [
      app: :auth_plug,
      version: "1.4.0",
      elixir: "~> 1.12",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      package: package(),
      description: "Turnkey Auth Plug lets you protect any route in an Elixir/Phoenix App.",
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test,
        c: :test
      ]
    ]
  end

  # defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      # uncomment the following line to run the demo app: mix run --no-halt
      # mod: {AuthPlug.Application, []}
      env: [
        api_key: System.get_env("AUTH_API_KEY")
      ]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # Httpoison for outbound HTTP Requests: hex.pm/packages/httpoison
      {:httpoison, "~> 1.8.0"},

      # JWT sign/verify: github.com/joken-elixir/joken
      {:joken, "~> 2.4.1"},

      # Plug helper functions: github.com/elixir-plug/plug
      {:plug, "~> 1.12.1"},

      # Decoding JSON data: https://hex.pm/packages/jason
      {:jason, "~> 1.2.2"},

      # Track coverage: github.com/parroty/excoveralls
      {:excoveralls, "~> 0.14.3", only: :test},

      # See: github.com/dwyl/auth_plug_example
      {:plug_cowboy, "~> 2.5.2", only: [:dev, :test]},

      # See: https://github.com/dwyl/useful
      {:useful, "~> 0.4.0"},

      # For publishing Hex.docs:
      {:ex_doc, "~> 0.25.3", only: :dev},
      {:credo, "~> 1.5", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.1", only: [:dev], runtime: false}
    ]
  end

  defp package() do
    [
      files:
        ~w(lib/auth_plug.ex lib/auth_plug_optional.ex lib/helpers.ex lib/token.ex LICENSE mix.exs README.md),
      name: "auth_plug",
      licenses: ["GNU GPL v2.0"],
      maintainers: ["dwyl"],
      links: %{"GitHub" => "https://github.com/dwyl/auth_plug"}
    ]
  end

  defp aliases do
    [
      c: ["coveralls.html"]
    ]
  end
end
