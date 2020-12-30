# [Elixir JSON](https://hex.pm/packages/json)

[![Build Status](https://travis-ci.org/cblage/elixir-json.svg?branch=master)](https://travis-ci.org/cblage/elixir-json) [![Hex.pm](https://img.shields.io/hexpm/dt/json.svg?style=flat-square)](https://hex.pm/packages/json) [![Coverage Status](https://coveralls.io/repos/github/cblage/elixir-json/badge.svg?branch=master)](https://coveralls.io/github/cblage/elixir-json?branch=master) [![Inline docs](http://inch-ci.org/github/cblage/elixir-json.svg)](http://inch-ci.org/github/cblage/elixir-json)
                                                                                                                                     
This library provides a natively implemented JSON encoder and decoder for Elixir.

You can find the package in [hex.pm](https://hex.pm/packages/json) and the documentation in [hexdocs.pm](https://hexdocs.pm/json/readme.html).

All contributions are welcome!

# Installing

Simply add ```{:json, "~> 1.4"}``` to your project's ```mix.exs``` and run ```mix deps.get```.

# Usage

Encoding an Elixir type
```elixir
  @doc "
	JSON encode an Elixir list
  "	
  list = [key: "this will be a value"]
  is_list(list)
  # true
  list[:key]
  # "this will be a value"
  {status, result} = JSON.encode(list)
  # {:ok, "{\"key\":\"this will be a value\"}"}
  String.length(result)
  # 41
```

Decoding a list from a string that contains JSON
```elixir
  @doc "
	JSON decode a string into an Elixir list
  "
  json_input = "{\"key\":\"this will be a value\"}"
  {status, list} = JSON.decode(json_input)
	{:ok, %{"key" => "this will be a value"}}
  list[:key]
  # nil
  list["key"]
  # "this will be a value"
```

At any time, you can turn on verbose logging for this library only. 
To do so, head to config file of your application and add below lines:

```elixir
use Mix.Config

config :logger, level: :debug

config :json, log_level: :debug
```

Note that, changing only `:logger` level to `:info`, `:warn` or `:error` will silent `:json` too.

# License
The Elixir JSON library is available under the [BSD 3-Clause aka "BSD New" license](http://www.tldrlegal.com/l/BSD3)
