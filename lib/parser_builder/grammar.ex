defmodule ParserBuilder.Grammar do
  @moduledoc false

  def new() do
    %{}
  end

  def add_rule(grammar, rule_name, rule_body) do
    grammar
    |> Map.put(rule_name, rule_body)
  end

  def lookup_rule(grammar, rule_name) do
    grammar
    |> Map.get(rule_name, [])
  end

  def merge_grammar_with_overrides(grammar, overrides) do
    overrides
    |> (&Map.merge(grammar, &1)).()
  end
end
