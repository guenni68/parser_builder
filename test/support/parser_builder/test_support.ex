defmodule ParserBuilder.TestSupport do
  @moduledoc false

  defmacro __using__(opts) do
    test_file = Keyword.get(opts, :tests)
    parser_module = Keyword.get(opts, :parser_module)

    tests =
      test_file
      |> extract_tests()
      |> Macro.escape()

    quote do
      import unquote(parser_module)

      @external_resource file = unquote(test_file)
      defmacro __using__(_opts) do
        imports =
          quote do
            import unquote(get_parser_module())
          end

        tests =
          get_tests()
          |> Enum.flat_map(&make_test/1)

        [imports | tests]
      end

      def get_tests() do
        unquote(tests)
      end

      defp get_parser_module() do
        unquote(parser_module)
      end

      defp make_test(x) do
        unquote(__MODULE__).make_test(x)
      end
    end
  end

  defp extract_tests(file_name) do
    {:ok, {'tests', _attrs, tests}, _remainder} =
      :erlsom.simple_form_file(
        file_name,
        nameFun: fn name, _namespace, _prefix -> name end
      )

    tests
    |> Enum.flat_map(&transform_test_node/1)
  end

  defp transform_test_node({_tag, _atts, []}) do
    []
  end

  defp transform_test_node({_tag, [{_, rulename} | _], kids}) do
    rulename =
      rulename
      |> to_string()

    kids =
      kids
      |> Enum.flat_map(&transform_test_child_node/1)

    [{rulename, kids}]
  end

  defp transform_test_node(_) do
    []
  end

  defp transform_test_child_node({'pass', [{_, input} | _], []}) do
    [{:pass, to_string(input)}]
  end

  defp transform_test_child_node({'fail', [{_, input} | _], []}) do
    [{:fail, to_string(input)}]
  end

  defp transform_test_child_node(_) do
    []
  end

  def make_test({rule_name_string, kids}) do
    asserts =
      kids
      |> Enum.flat_map(&make_assert/1)

    [
      quote do
        test "'#{unquote(rule_name_string)}'" do
          parser =
            unquote(rule_name_string)
            |> from_rule_name_strict()
            |> finalize()

          unquote(asserts)
        end
      end
    ]
  end

  def make_test(_) do
    []
  end

  defp make_assert({:pass, input_string}) do
    [
      quote do
        assert {:done, {:ok, _result, ""}} = parser.(unquote(input_string))
      end
    ]
  end

  defp make_assert({:fail, input_string}) do
    [
      quote do
        assert {:done, {:error, _reason}} = parser.(unquote(input_string))
      end
    ]
  end

  defp make_assert(_) do
    []
  end
end
