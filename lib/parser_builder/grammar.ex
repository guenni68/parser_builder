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

  def override_rule(grammar, rule_name, overrides) do
    grammar
    |> Map.update(
      rule_name,
      overrides,
      fn
        [{tag, atts, body}] when tag in [:tag, :wrap, :ignore] ->
          [{tag, atts, overrides}]

        _ ->
          overrides
      end
    )
  end
end
