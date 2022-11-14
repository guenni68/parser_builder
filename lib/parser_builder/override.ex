defmodule ParserBuilder.Override do
  @moduledoc false

  alias ParserBuilder.Helpers

  def new() do
    %{}
  end

  def add_rule_override(overrides, rule_name, literal) do
    overrides
    |> Map.update(rule_name, [literal], fn literals -> [literal | literals] end)
  end

  def add_rule_overrides(overrides, rule_name, literals) do
    literals
    |> Enum.reduce(
      overrides,
      fn literal, acc -> add_rule_override(acc, rule_name, literal) end
    )
  end

  def get_overrides(overrides) do
    overrides
    |> Enum.map(fn {k, v} -> {k, convert_to_rule_body(v)} end)
    |> Enum.into(%{})
  end

  def empty?(overrides) do
    overrides
    |> Enum.empty?()
  end

  def finalize(overrides) do
    overrides
    |> Enum.map(fn {k, vs} -> {k, Enum.reverse(vs)} end)
    |> Enum.into(%{})
  end

  defp convert_to_rule_body([rule]) do
    [make_case_sensitive(rule)]
  end

  defp convert_to_rule_body(rules) do
    [
      rules
      |> Enum.map(&make_case_sensitive/1)
      |> Enum.map(&Helpers.make_item([&1]))
      |> (&Helpers.make_one_of(&1)).()
    ]
  end

  defp make_case_sensitive(string_literal) do
    {:cs_literal, %{value: string_literal}, []}
  end
end
