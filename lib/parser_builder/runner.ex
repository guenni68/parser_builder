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
    backstops_with_new_input =
      backstops
      |> Backstops.add_new_input(input_string)

    case fun.(input_string) do
      {:done, {:ok, _results, _remainder}} = result ->
        result

      {:done, {:error, _reason}} = failed ->
        case Backstops.backtrack(backstops_with_new_input, failed) do
          {new_backstops, next_fun, accumulated_input} ->
            run_parser(
              new_backstops,
              lookup_fun,
              fn _ -> next_fun.(accumulated_input) end,
              ""
            )

          _ ->
            failed
        end

      {:error, _reason} = error ->
        {:done, error}

      {:continue = tag, continuation} ->
        {tag,
         fn new_input_string ->
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
end
