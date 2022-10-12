defmodule ParserBuilder do
  alias ParserBuilder.Grammar

  defmacro __using__(opts) do
    file = Keyword.get(opts, :file)

    {:ok, {'grammar', _attrs, rules}, _remainder} =
      :erlsom.simple_form_file(
        file,
        nameFun: fn name, _namespace, _prefix -> name end
      )

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
        parse_string_non_strict(rule_overrides, start_rule_name, input_string)
      end

      def parse_string_non_strict(rule_overrides \\ %{}, start_rule_name, input_string) do
        route(rule_overrides, start_rule_name, input_string, &Runner.parse_string_non_strict/3)
      end

      def parse_string_strict(rule_overrides \\ %{}, start_rule_name, input_string) do
        route(rule_overrides, start_rule_name, input_string, &Runner.parse_string_strict/3)
      end

      defp route(rule_overrides \\ %{}, start_rule_name, input_string, runner_fun) do
        get_rules()
        |> Grammar.merge_grammar_with_overrides(rule_overrides)
        |> runner_fun.(
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
