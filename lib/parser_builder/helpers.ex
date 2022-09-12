defmodule ParserBuilder.Helpers do
  @moduledoc false

  alias ParserBuilder.Grammar

  @done :done

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
        |> (fn x -> make_item([x]) end).()
      end)
      |> make_one_of()

    Grammar.override_rule(grammar, rule_name, [converted])
  end

  def make_case_sensitive(string_literal) do
    {:cs_literal, %{value: string_literal}, []}
  end

  def make_item(rules) do
    {:item, %{}, rules}
  end

  def make_one_of(rules) do
    {:oneOf, %{}, rules}
  end

  def done_ok(result, remainder) do
    {@done, {:ok, result, remainder}}
  end

  def done_error(msg \\ :parse_failed) do
    {@done, {:error, msg}}
  end
end
