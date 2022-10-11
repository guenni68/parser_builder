defmodule ParserBuilder.Runner.Strict do
  @moduledoc false

  alias ParserBuilder.{
    Backstops,
    Helpers
  }

  def run_parser(backstops \\ Backstops.new(), lookup_fun, fun, input_string)

  def run_parser(backstops, lookup_fun, fun, input_string) do
    backstops_with_new_input =
      backstops
      |> Backstops.add_new_input(input_string)

    case fun.(input_string) do
      {:done, {:ok, _results, ""}} = result ->
        result

      {:done, {:ok, _results, _remainder}} ->
        backtrack(backstops_with_new_input, lookup_fun, :parse_failed, &run_parser/4)

      {:done, {:error, reason}} ->
        backtrack(backstops_with_new_input, lookup_fun, reason, &run_parser/4)

      {:error, _reason} = error ->
        {:done, error}

      {:continue = tag, continuation} ->
        {tag,
         fn
           "" ->
             backtrack(
               backstops_with_new_input,
               lookup_fun,
               :parse_failed,
               &run_without_new_input/4
             )

           new_input_string ->
             run_parser(
               backstops_with_new_input,
               lookup_fun,
               continuation,
               new_input_string
             )
         end}

      {:lookup, fun} ->
        continuation = fun.(lookup_fun)
        run_parser(backstops_with_new_input, lookup_fun, continuation, "")

      {:backstops, [first_alternative | other_alternatives]} ->
        new_backstops =
          backstops_with_new_input
          |> Backstops.add_new_backstops(other_alternatives)

        run_parser(new_backstops, lookup_fun, first_alternative, "")
    end
  end

  defp run_without_new_input(backstops, lookup_fun, parse_fun, "" = fake_input) do
    case parse_fun.(fake_input) do
      {:done, {:ok, _results, ""}} = result ->
        result

      {:done, {:ok, _result, _remainder}} ->
        backtrack(backstops, lookup_fun, :parse_failed, &run_without_new_input/4)

      {:done, {:error, reason}} ->
        backtrack(backstops, lookup_fun, reason, &run_without_new_input/4)

      {:error, _reason} = error ->
        {:done, error}

      {:continue, _continuation} ->
        backtrack(backstops, lookup_fun, :parse_failed, &run_without_new_input/4)

      {:lookup, fun} ->
        continuation = fun.(lookup_fun)
        run_without_new_input(backstops, lookup_fun, continuation, "")

      {:backstops, [first_alternative | other_alternatives]} ->
        new_backstops =
          backstops
          |> Backstops.add_new_backstops(other_alternatives)

        run_without_new_input(new_backstops, lookup_fun, first_alternative, "")
    end
  end

  defp backtrack(backstops, lookup_fun, reason, continuation) do
    Helpers.backtrack(backstops, lookup_fun, reason, continuation)
  end
end
