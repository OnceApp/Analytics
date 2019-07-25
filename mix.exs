defmodule Analytics.MixProject do
  use Mix.Project

  def project do
    [
      app: :analytics,
      package: package(),
      version: "0.1.0",
      elixir: "~> 1.8",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: description(),
      source_url: "https://github.com/OnceApp/Analytics",
      elixirc_paths: elixirc_paths(Mix.env())
    ]
  end

  defp description() do
    "Send analytics to Kinesis efficiently"
  end

  defp package() do
    [
      name: "analytics",
      files: ~w(lib .formatter.exs mix.exs README* LICENSE*),
      links: %{"Github" => "https://github.com/OnceApp/Analytics"},
      licenses: ["MIT"]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {Analytics.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ex_aws, "~> 2.0"},
      {:ex_aws_kinesis, "~> 2.0"},
      {:hackney, "~> 1.9"},
      {:sweet_xml, "~> 0.6"},
      {:configparser_ex, "~> 2.0"},
      {:gen_stage, "~> 0.14"},
      {:earmark, "~> 1.2", only: :dev},
      {:ex_doc, "~> 0.19.3", only: :dev},
      {:decimal, "~> 1.0"}
    ]
  end

  defp elixirc_paths(:test), do: ["test/support", "lib"]
  defp elixirc_paths(_), do: ["lib"]
end
