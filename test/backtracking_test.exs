defmodule ParserBuilder.BacktrackingTest do
  use ExUnit.Case

  defp parse_string(rule, string) do
    ParserBuilder.MyTestParser.parse_string(rule, string)
  end

  defp from_rule(rule_name) do
    fn input -> parse_string(rule_name, input) end
  end

  defp parse() do
    from_rule("backtracking1")
  end

  test "backtracking1" do
    assert {:done, {:ok, ["abcd"], ""}} = parse().("abcd")
    assert {:done, {:ok, ["afgh"], ""}} = parse().("afgh")
    assert {:done, {:ok, ["aijk"], ""}} = parse().("aijk")
  end
end
