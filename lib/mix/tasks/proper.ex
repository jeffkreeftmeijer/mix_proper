defmodule Mix.Tasks.Proper do
  use Mix.Task

  @shortdoc "Run property tests (uses PropEr)"
  @moduledoc @shortdoc

  @doc false
  def run([]) do
    "test/**/*_prop.exs"
    |> Path.wildcard
    |> run
  end
  def run(files) do
    files
    |> Kernel.ParallelRequire.files
    |> run_properties_for_modules
    |> finish
  end

  def run_properties_for_modules([]) do
    IO.puts "There are no properties to run"
  end
  def run_properties_for_modules(modules) do
    Enum.reduce(modules, true, fn(module, current_status) ->
      module.__info__(:functions)
      |> Enum.filter(&property?/1)
      |> Enum.map(fn({name, 0}) ->
        :proper.quickcheck(apply(module, name, []))
      end)
      |> determine_status(current_status)
    end)
  end

  defp property?({name, 0}) do
    name
    |> Atom.to_string
    |> String.starts_with?("prop_")
  end
  defp property?({_name, _arity}), do: false

  defp determine_status(results, true), do: Enum.all?(results)
  defp determine_status(_, _), do: false

  defp finish(false), do: System.at_exit(fn(_) -> exit({:shutdown, 1}) end)
  defp finish(_), do: :ok
end
