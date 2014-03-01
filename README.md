# Elixir JSON

[![Build Status](https://travis-ci.org/cblage/elixir-json.png?branch=master)](https://travis-ci.org/cblage/elixir-json)

This library provides a natively implemented JSON encoder and decoder for Elixir.

All contributions are welcome.
## Installing

Simply add ```{ :json, github: "cblage/elixir-json"}``` to your project's ```mix.exs``` file, in the dependencies list and run ```mix deps.get json```.

### Example for a project that already uses [Dynamo](https://github.com/elixir-lang/dynamo):
```elixir
defp deps do
    [ { :cowboy, github: "extend/cowboy" },
      { :dynamo, github: "elixir-lang/dynamo" },
      { :json,   github: "cblage/elixir-json"} ]
end
```

## Usage

```elixir
  JSON.encode([result: "this will be a elixir result"])
  {:ok, "{\"result\":\"this will be a elixir result\"}"}
```

```elixir
  JSON.decode("{\"result\":\"this will be a elixir result\"}")
  {:ok, %{"result" => "this will be a elixir result"}}
```

## Dynamo Filter

Elixir JSON includes a convenient filter for the [Dynamo](https://github.com/elixir-lang/dynamo) web framework.

If you want to use it, simply add Elixir JSON to your project's dependencies, and add the following line to your router:
```elixir 
filter JSON.Dynamo.Filter
```

Afterwards, to generate JSON responses, simply use ```conn.put_private``` and set the ```:result_object``` to whatever you want to be converted to JSON:
```elixir
  get "/whoami" do
    conn.put_private :result_object, [ name: "Carlos", city: "New York", likes: "Programming" ]
  end
```


## License
The Elixir JSON library is available under the [BSD 3-Clause aka "BSD New" license](http://www.tldrlegal.com/l/BSD3)
