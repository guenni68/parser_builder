defmodule ParserBuilder do
  alias ParserBuilder.Grammar

  defmacro __using__(opts) do
    file = Keyword.get(opts, :file)

    {:ok, xml_string} = File.read(file)
    {:ok, {'grammar', _attrs, rules}, _remainder} = :erlsom.simple_form(xml_string)

    rules =
      rules
      |> convert_tree()
      |> Enum.map(&create_rule/1)
      |> Enum.reduce(Grammar.new(), fn {k, v}, acc -> Grammar.add_rule(acc, k, v) end)
      |> Macro.escape()

    quote do
      alias ParserBuilder.{
        Runner,
        Grammar
      }

      @external_resource file = unquote(file)

      def get_rules() do
        unquote(rules)
      end

      def parse_string(rule_overrides \\ %{}, start_rule_name, input_string) do
        get_rules()
        |> Grammar.merge_grammar_with_overrides(rule_overrides)
        |> Runner.parse_string(
          start_rule_name,
          input_string
        )
      end
    end
  end

  defp create_rule({:rule, %{id: name} = attrs, body}) do
    body =
      case attrs do
        %{postprocess: "tag"} ->
          [{:tag, %{name: name}, body}]

        %{postprocess: "wrap"} ->
          [{:wrap, %{}, body}]

        %{postprocess: "ignore"} ->
          [{:ignore, %{}, body}]

        _ ->
          body
      end

    {name, body}
  end

  defp convert_tree(acc \\ [], rules)

  defp convert_tree(acc, []) do
    acc
    |> Enum.reverse()
  end

  defp convert_tree(acc, [{name, atts, children} | rest]) do
    name =
      name
      |> to_string()
      |> String.to_atom()

    atts =
      atts
      |> Enum.map(fn {k, v} ->
        {
          k
          |> to_string()
          |> String.to_atom(),
          v
          |> to_string()
        }
      end)
      |> Enum.into(%{})

    children = convert_tree([], children)
    convert_tree([{name, atts, children} | acc], rest)
  end
end
