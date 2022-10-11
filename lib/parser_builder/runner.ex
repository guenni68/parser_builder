defmodule ParserBuilder.Runner do
  @moduledoc false

  alias ParserBuilder.{
    Grammar,
    Parser
  }

  alias ParserBuilder.Runner.{
    NonStrict,
    Strict
  }

  def parse_string_non_strict(grammar, initial_rule_name, input_string) do
    route(grammar, initial_rule_name, input_string, &NonStrict.run_parser/3)
  end

  def parse_string_strict(grammar, initial_rule_name, input_string) do
    route(grammar, initial_rule_name, input_string, &Strict.run_parser/3)
  end

  defp route(grammar, initial_rule_name, input_string, runner_fun) do
    lookup_fun = fn rule_name -> Grammar.lookup_rule(grammar, rule_name) end
    initial_rules = lookup_fun.(initial_rule_name)

    initial_fun = Parser.create_initial_parser_fun(initial_rules)

    runner_fun.(lookup_fun, initial_fun, input_string)
  end
end
