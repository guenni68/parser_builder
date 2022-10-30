defmodule ParserBuilder.MyTestSupport do
  @moduledoc false

  use ParserBuilder.TestSupport,
    parser_module: ParserBuilder.MyTestParser,
    tests: "priv/test/sample_tests.xml"
end
