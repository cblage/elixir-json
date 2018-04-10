# Elixir JSON

[![Coverage Status](https://coveralls.io/repos/github/cblage/elixir-json/badge.svg?branch=master)](https://coveralls.io/github/cblage/elixir-json?branch=master)
[![Hex.pm](https://img.shields.io/hexpm/v/json.svg?style=flat-square)](https://hex.pm/packages/json)
[![Build Status](https://travis-ci.org/cblage/elixir-json.svg?branch=master)](https://travis-ci.org/cblage/elixir-json) [![Inline docs](http://inch-ci.org/github/cblage/elixir-json.svg)](http://inch-ci.org/github/cblage/elixir-json) 
[![Hex.pm](https://img.shields.io/hexpm/dt/json.svg?style=flat-square)](https://hex.pm/packages/json) 
                                                                                                                                                                                                                                         
  

This library provides a natively implemented JSON encoder and decoder for Elixir.

All contributions are welcome.
## Installing

Simply add ```{:json, "~> 1.0"}``` to your project's ```mix.exs``` file, in the dependencies list and run ```mix deps.get json```.

### Example for a project that already uses [Plug](https://github.com/elixir-plug/plug):
```elixir
defp deps do
  [{:cowboy, "~> 1.0.0"},
   {:plug, "~> 1.0"},
   {:json, "~> 1.0"}]
end
```

## Usage

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

## License
The Elixir JSON library is available under the [BSD 3-Clause aka "BSD New" license](http://www.tldrlegal.com/l/BSD3)
