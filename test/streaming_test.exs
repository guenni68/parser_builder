defmodule ParserBuilder.StreamingTest do
  use ExUnit.Case

  alias ParserBuilder.{
    MyTestParser,
    Override
  }

  test "conversation" do
    partial = "final"
    final = "partial"

    overrides =
      Override.new()
      |> Override.add_rule_override("rfc3501_tag", partial)

    parser = MyTestParser.from_rule_name(overrides, "test_conversation")
    sp1 = MyTestParser.streaming_parser(parser, "xx_partial", "xx_final")

    assert {:partial_result, [^final], sp3} = sp1.(final)
    assert {:continue, sp2} = sp1.("p")
    assert {:partial_result, [^final], _} = sp2.("artial")

    assert {:done, {:ok, [^partial], "remainder"}} = sp3.("#{partial}remainder")

    assert {:done, {:error, _reason}} = sp3.("wrong")
  end
end
