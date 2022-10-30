defmodule ParserBuilder.EOFTest do
  use ExUnit.Case

  defp parse(input) do
    ParserBuilder.MyTestParser.parse_string("optionalAtEnd1", input)
  end

  test "optionalAtEnd1" do
    assert {:continue, cont1} = parse("one")
    assert {:done, {:ok, ["one"], ""}} = cont1.("")
    assert {:done, {:ok, ["one", "four"], ""}} = cont1.("four")
    assert {:continue, cont2} = cont1.("two")
    assert {:done, {:ok, ["one", "two"], ""}} = cont2.("")
  end
end
