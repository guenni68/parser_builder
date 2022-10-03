defmodule ParserBuilder.Runner do
  @moduledoc false

  alias ParserBuilder.{
    Grammar,
    Parser,
    Backstops
  }

  def parse_string(grammar, initial_rule_name, input_string) do
    lookup_fun = fn rule_name -> Grammar.lookup_rule(grammar, rule_name) end
    initial_rules = lookup_fun.(initial_rule_name)

    initial_fun = Parser.create_initial_parser_fun(initial_rules)

    run_parser(lookup_fun, initial_fun, input_string)
  end

  defp run_parser(backstops \\ Backstops.new(), lookup_fun, fun, input_string)

  defp run_parser(backstops, lookup_fun, fun, input_string) do
    input_chars =
      input_string
      |> String.to_charlist()

    backstops =
      backstops
      |> Backstops.add_new_input(input_string)

    case fun.(input_chars) do
      {:done, {:ok, _results, _remainder}} = result ->
        result

      {:done, {:error, _reason}} = failed ->
        case Backstops.backtrack(backstops, failed) do
          {new_backstops, next_fun, next_input} ->
            run_parser(new_backstops, lookup_fun, next_fun, next_input)

          _ ->
            failed
        end

      {:continue = tag, continuation} ->
        {tag,
         fn input_string ->
           run_parser(backstops, lookup_fun, continuation, input_string)
         end}

      {:lookup, fun} ->
        continuation = fun.(lookup_fun)
        run_parser(backstops, lookup_fun, continuation, input_string)

      {:backstops, [alternative | alternatives]} ->
        backstops =
          backstops
          |> Backstops.add_new_backstops(alternatives)

        run_parser(backstops, lookup_fun, alternative, "")
    end
  end
end
