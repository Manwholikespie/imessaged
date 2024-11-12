defmodule Imessaged.MixProject do
  use Mix.Project

  def project do
    [
      app: :imessaged,
      version: "0.1.0",
      elixir: "~> 1.17",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      compilers: [:elixir_make] ++ Mix.compilers(),
      make_clean: ["clean"],
      make_cwd: "c_src",
      aliases: aliases()
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
      {:elixir_make, "~> 0.7.3"}
    ]
  end

  defp aliases do
    [
      compile: ["copy_sdef", "compile"]
    ]
  end
end
