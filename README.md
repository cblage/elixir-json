# Elixir JSON

[![Build Status](https://travis-ci.org/cblage/elixir-json.png?branch=master)](https://travis-ci.org/cblage/elixir-json)

This library provides a natively implemented JSON encoder and decoder for Elixir.

All contributions are welcome.
## Installing

Simply add ```{:json, "~> 1.0"}``` to your project's ```mix.exs``` file, in the dependencies list and run ```mix deps.get json```.

### Example for a project that already uses [Dynamo](https://github.com/dynamo/dynamo):
```elixir
defp deps do
    [ { :cowboy, "~> 1.0.0" },
      { :dynamo, github: "dynamo/dynamo" },
      { :json,   "~> 1.0.0"} ]
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
