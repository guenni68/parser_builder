defmodule ParserBuilder.Override do
  @moduledoc false

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
    |> Map.to_list()
    |> Enum.sort_by(fn {k, _v} -> k end)
  end

  def empty?(overrides) do
    overrides
    |> Enum.empty?()
  end
end
