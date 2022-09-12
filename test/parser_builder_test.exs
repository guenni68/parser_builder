defmodule ParserBuilderTest do
  use ExUnit.Case
  doctest ParserBuilder

  test "grammar is not empty" do
    rule_count =
      ParserBuilderModule.get_rules()
      |> Enum.count()

    assert rule_count == 450
  end
end
