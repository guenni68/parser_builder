# ParserBuilder

ParserBuilder is a library that allows you to simply generate a resumable parser with unlimited backtracking from an easily modifiable grammar (expressed in XML).

What sets this parser library apart from others is that you don't define your parser by expressing the grammar and rules in Elixir code but rather in a single XML file. I've personally used this approach for an ABNF grammar with 460+ rules and added **postprocessing**, such as tagging, ignoring and replacing values, or any combination there of, as needed in the XML file instead of Elixir code. 

## Features

* unlimited backtracking.
* resumable parsing, in case that the input cannot be provided in one piece.
* overridable rules. If some rules can only be known at runtime, you can override the rules from the grammar.
* easily add postprocessing, such as tagging, ignoring and replacing intermediate parse results.

## Usage

```elixir
defmodule MyParser do
  use ParserBuilder, file: "priv/my_grammar.xml"
end
```

This will inject the following functions into your MyParser module:

* parse_string(rule_name, string), calls parse_string_non_strict(rule_name, string)
* parse_string_strict(rule_name, string)
* parse_string_non_strict(rule_name, string)

## Examples

```xml
<?xml version="1.0" encoding="UTF-8" ?>
<grammar xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:noNamespaceSchemaLocation="../abnf.xsd">
  <rule id="simple1">
    <cs_literal value="one"/>
  </rule>
</grammar>
```

use the above grammar in the MyParser module and call

```elixir
{:continue, cont1} = MyParse.parse_string("simple1", "on")
{:done, {:ok, ["one"], "rest"}} = cont1.("erest")
```

if you want the parser to fail if it does not consume the entire input use the following function instead:

```elixir
{:continue, cont1} = MyParse.parse_string_strict("simple1", "on")
{:done, {:error, _reason}} = cont1.("erest")
{:done, {:ok, ["one"], ""}} = cont1.("e")
```

This library features the following "xmlized" abnf combinators:
* `<optional>...</optional>`
* `<many>...</many>`
* `<manyOne>...</manyOne>`
* `<oneOf><item>...</item>...</oneOf> (backtracking included)`
* `<atMost count="3">...</atMost>`
* `<atLeast count="2">...</atLeast>`
* `<exactly count="2">...</exactly>`
* `<repeat min="1" max="5">...</repeat>`

and the following "primitives":
* `<cs_literal value="some"/>` (**c**ase **s**ensitive)
* `<ci_literal value="else"/>` (**c**ase **i**nsensitive, explicit)
* `<literal value="else"/>` (**c**ase **i**nsensitive, implicit)

and a number of result aggregation features inspired by and shamelessly copied from nimble_parsec:
* `<tag name="tag1">...</tag>`
* `<ignore>...</ignore>`
* `<replace value="replacement">...</replacement>`
* `<untagAndFlatten>...</untagAndFlatten>`

Named rules from the top level are referenced like this:
* `<ruleRef uri="nameOfTheRule"/>`

For a more comprehensive demonstration of this library's features please have a look at the tests.

The schema file for this version can be found here: [abnf.xsd](https://github.com/guenni68/parser_builder/blob/master/priv/schemas/abnf_v1.0.0.xsd)

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed by adding `parser_builder` to your list
of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:parser_builder, "~> 1.0.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can be found
at [https://hexdocs.pm/parser_builder](https://hexdocs.pm/parser_builder).

