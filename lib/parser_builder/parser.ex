defmodule ParserBuilder.Parser do
  @moduledoc false

  alias ParserBuilder.{
    Grammar,
    Runner
  }

  def parse_string(grammar, initial_rule_name, input_string) do
    lookup_fun = fn rule_name -> Grammar.lookup_rule(grammar, rule_name) end
    initial_rules = lookup_fun.(initial_rule_name)

    initial_fun = Runner.create_initial_parser_fun(initial_rules)

    run_parser(lookup_fun, initial_fun, input_string)
  end

  defp run_parser(lookup_fun, fun, input_string)

  defp run_parser(lookup_fun, fun, input_string) do
    input_chars =
      input_string
      |> String.to_charlist()

    case fun.(input_chars) do
      {:done, {:ok, _results, _remainder}} = result ->
        result

      {:continue, continuation} ->
        {:continue,
         fn input_string ->
           run_parser(lookup_fun, continuation, input_string)
         end}
    end
  end
end
