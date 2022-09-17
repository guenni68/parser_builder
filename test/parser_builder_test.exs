defmodule ParserBuilderTest do
  use ExUnit.Case
  doctest ParserBuilder

  test "simple cs literal" do
    result = ParserBuilderModule.parse_string("cs_string", "strings and more")
    assert {:done, {:ok, ["strings"], " and more"}} = result
  end

  test "two strings" do
    result = ParserBuilderModule.parse_string("twoStrings", "meyou")
    assert {:done, {:ok, ["me", "you"], ""}} = result
  end

  test "ci string" do
    result = ParserBuilderModule.parse_string("caseInsensitive", "mEyOu")
    assert {:done, {:ok, ["mE", "yOu"], ""}} = result
  end

  test "ignore1" do
    result = ParserBuilderModule.parse_string("ignore1", "doignorethis")
    assert {:done, {:ok, ["do", "this"], ""}} = result
  end

  test "tagged1" do
    result = ParserBuilderModule.parse_string("tagged1", "thisistagged")
    assert {:done, {:ok, ["this", "is", {:tag1, ["tagged"]}], ""}} = result
  end

  test "replace1" do
    result = ParserBuilderModule.parse_string("replace1", "youshouldreplacethis")
    assert {:done, {:ok, ["you", "should", "replace", "that"], ""}} = result
  end

  test "continuation" do
    result = ParserBuilderModule.parse_string("cs_string", "string")
    assert {:continue, continuation} = result
    assert {:done, {:ok, ["strings"], ""}} = continuation.("s")
  end
end
