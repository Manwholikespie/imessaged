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
      make_env: make_env()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {Imessaged.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:elixir_make, "~> 0.7.3"},
      {:plug_cowboy, "~> 2.7"},
      {:jason, "~> 1.4"}
    ]
  end

  defp make_env do
    base = %{
      "ERTS_INCLUDE_DIR" => "#{:code.root_dir()}/erts-#{:erlang.system_info(:version)}/include",
      "ERL_INTERFACE_INCLUDE_DIR" => "#{:code.root_dir()}/usr/include",
      "ERL_INTERFACE_LIB_DIR" => "#{:code.root_dir()}/usr/lib"
    }

    # Allow users to override environment variables
    Enum.reduce(System.get_env(), base, fn {key, value}, acc ->
      if String.starts_with?(key, "IMESSAGED_"), do: Map.put(acc, key, value), else: acc
    end)
  end
end
