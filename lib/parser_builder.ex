defmodule ParserBuilder do
  @moduledoc """

    usage:

    defmodule MyParser do
      use ParserBuilder, file: "path_to_my_grammar.xml"
    end


  """

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
        Grammar,
        Override
      }

      @external_resource file = unquote(file)

      def get_rules() do
        unquote(rules)
      end

      def parse_string(rule_overrides \\ Override.new(), start_rule_name, input_string) do
        parse_string_non_strict(rule_overrides, start_rule_name, input_string)
      end

      def parse_string_non_strict(rule_overrides \\ Override.new(), start_rule_name, input_string) do
        route(rule_overrides, start_rule_name, input_string, &Runner.parse_string_non_strict/3)
      end

      def parse_string_strict(rule_overrides \\ Override.new(), start_rule_name, input_string) do
        route(rule_overrides, start_rule_name, input_string, &Runner.parse_string_strict/3)
      end

      def from_rule_name(rule_overrides \\ Override.new(), rule_name) do
        fn input -> parse_string(rule_overrides, rule_name, input) end
      end

      def from_rule_name_non_strict(rule_overrides \\ Override.new(), rule_name) do
        fn input -> parse_string_non_strict(rule_overrides, rule_name, input) end
      end

      def from_rule_name_strict(rule_overrides \\ Override.new(), rule_name) do
        fn input -> parse_string_strict(rule_overrides, rule_name, input) end
      end

      @doc """
      _seales_ the parser given. The resulting parser will not produces a continuation.
      """
      def finalize(parser) do
        unquote(__MODULE__).finalize(parser)
      end

      def streaming_parser(parser, partial_tag, final_tag) do
        unquote(__MODULE__).streaming_parser(parser, partial_tag, final_tag)
      end

      defp route(rule_overrides, start_rule_name, input_string, runner_fun) do
        get_rules()
        |> Grammar.merge_grammar_with_overrides(rule_overrides)
        |> runner_fun.(
          start_rule_name,
          input_string
        )
      end
    end
  end

  def finalize(parser) do
    fn input ->
      case parser.(input) do
        {:continue, continuation} ->
          continuation.("")

        done ->
          done
      end
    end
  end

  def streaming_parser(parser, partial_tag, final_tag) do
    partial_tag =
      partial_tag
      |> String.to_atom()

    final_tag =
      final_tag
      |> String.to_atom()

    reapply_parser(parser, parser, partial_tag, final_tag)
  end

  defp reapply_parser(initial_parser, curr_parser, partial_tag, final_tag)

  defp reapply_parser(initial_parser, curr_parser, partial_tag, final_tag) do
    fn input ->
      case curr_parser.(input) do
        {:done, {:ok, [{^partial_tag, result}], remainder}} ->
          next_parser = fn next_input ->
            reapply_parser(
              initial_parser,
              initial_parser,
              partial_tag,
              final_tag
            ).(remainder <> next_input)
          end

          {:partial_result, result, next_parser}

        {:done, {:ok, [{^final_tag, result}], remainder}} ->
          {:done, {:ok, result, remainder}}

        {:done, {:ok, _result, _remainder}} ->
          {:done, {:error, :conversation_discontinued}}

        {:continue, fun} ->
          next_fun =
            reapply_parser(
              initial_parser,
              fun,
              partial_tag,
              final_tag
            )

          {:continue, next_fun}

        error ->
          error
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
