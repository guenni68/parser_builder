defmodule ParserBuilder.Override do
  @moduledoc false

  def new() do
    %{}
  end

  def add_rule_override(overrides, rule_name, literal) do
    overrides
    |> Map.update(rule_name, [literal], fn literals -> [literal | literals] end)
  end
end
