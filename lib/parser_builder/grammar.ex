defmodule ParserBuilder.Grammar do
  @moduledoc false

  alias ParserBuilder.Helpers

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
        [{tag, atts, _body}] when tag in [:tag, :wrap, :ignore] ->
          [{tag, atts, overrides}]

        _ ->
          overrides
      end
    )
  end

  def merge_grammar_with_overrides(grammar, overrides) do
    if Enum.empty?(overrides) do
      grammar
    else
      overrides
      |> Enum.reduce(grammar, &convert_override/2)
    end
  end

  defp convert_override({rule_name, [override]}, grammar) do
    converted = make_case_sensitive(override)

    Grammar.override_rule(grammar, rule_name, [converted])
  end

  defp convert_override({rule_name, overrides}, grammar) do
    converted =
      overrides
      |> Enum.map(fn override ->
        override
        |> make_case_sensitive()
        |> (fn x -> Helpers.make_item([x]) end).()
      end)
      |> Helpers.make_one_of()

    Grammar.override_rule(grammar, rule_name, [converted])
  end

  def make_case_sensitive(string_literal) do
    {:cs_literal, %{value: string_literal}, []}
  end
end
