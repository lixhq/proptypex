defmodule PropTypex.Mixfile do
  use Mix.Project

  def project do
    [
      app: :proptypex,
      version: "0.0.2",
      elixir: "~> 1.4",
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod,
      deps: deps(),
      description: "PropTypex is a small library for validating data in maps, inspired by Reacts PropTypes",
      package: package()
    ]
  end

  def application do
    []
  end

  defp package do
    [
      maintainers: ["Simon Stender Boisen <ssb@lix.tech>"],
      licenses: ["MIT"],
      links: %{
        "GitHub" => "https://github.com/lixhq/proptypex"
      }
    ]
  end

  defp deps do
    [{:mix_test_watch, "~> 0.3", only: :test}]
  end
end
