defmodule ParserBuilder.Parser do
  @moduledoc false

  alias ParserBuilder.{
    Helpers,
    Grammar,
    Backstop,
    Runner
  }

  def parse_string(grammar, grammar_overrides, initial_rule_name, input_string) do
    new_grammar = Helpers.merge_grammar_with_overrides(grammar, grammar_overrides)
    lookup_fun = fn rule_name -> Grammar.lookup_rule(new_grammar, rule_name) end
    initial_rules = lookup_fun.(initial_rule_name)

    initial_fun = Runner.create_initial_parser_fun(lookup_fun, initial_rules)

    iterate(initial_fun, input_string)
  end

  @done :done
  @continue :continue
  @add_backstop :add_backstop
  @backtrack :backtrack

  defp iterate(backstops \\ Backstop.new(), fun, input_string)

  defp iterate(backstops, run_fun, input_string) do
    input_chars = String.to_charlist(input_string)

    case run_fun.(input_chars) do
      {@continue, next_fun} ->
        wrapped_fun = fn more_input -> iterate(backstops, next_fun, more_input) end
        {@continue, wrapped_fun}

      {@done, {:ok, _result, _remainder}} = response ->
        response

      {@done, {:error, _message}} = response ->
        response

      {@add_backstop, alternatives, next_fun} ->
        new_backstops =
          backstops
          |> Backstop.add_backstop(alternatives, input_string)

        iterate(new_backstops, next_fun, "")

      @backtrack ->
        case Backstop.backtrack(backstops) do
          {new_backstops, new_fun, acc_input} ->
            iterate(new_backstops, new_fun, acc_input)

          done_error ->
            done_error
        end
    end
  end
end
