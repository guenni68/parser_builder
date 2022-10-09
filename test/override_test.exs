defmodule ParserBuilder.OverrideTest do
  use ExUnit.Case

  alias ParserBuilder.Override

  test "override1" do
    parse_vanilla = fn input -> ParserBuilderModule.parse_string("override1", input) end

    override =
      Override.new()
      |> Override.add_rule_overrides("override1", ["dummy", "other"])

    parse_override = fn input ->
      ParserBuilderModule.parse_string(override, "override1", input)
    end

    assert {:done, {:ok, ["override"], ""}} = parse_vanilla.("override")
    assert {:done, {:ok, ["dummy"], ""}} = parse_override.("dummy")
    assert {:done, {:ok, ["other"], ""}} = parse_override.("other")
  end
end
