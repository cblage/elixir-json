# Elixir JSON

[![Build Status](https://travis-ci.org/cblage/elixir-json.png?branch=master)](https://travis-ci.org/cblage/elixir-json)

This library provides a natively implemented JSON encoder and decoder for Elixir.

All contributions are welcome.
## Installing

Simply add ```{:json, "~> 0.3.0"}``` to your project's ```mix.exs``` file, in the dependencies list and run ```mix deps.get json```.

### Example for a project that already uses [Dynamo](https://github.com/elixir-lang/dynamo):
```elixir
defp deps do
    [ { :cowboy, "~> 1.0.0" },
      { :dynamo, github: "elixir-lang/dynamo" },
      { :json,   "~> 0.3.0"} ]
end
```

## Usage

```elixir
  JSON.encode([result: "this will be a elixir result"])
  {:ok, "{\"result\":\"this will be a elixir result\"}"}
```

```elixir
  JSON.decode("{\"result\":\"this will be a elixir result\"}")
  {:ok, [result: "this will be a elixir result"]}
```

## License
The Elixir JSON library is available under the [BSD 3-Clause aka "BSD New" license](http://www.tldrlegal.com/l/BSD3)
