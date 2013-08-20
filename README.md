# Elixir JSON

[![Build Status](https://travis-ci.org/cblage/elixir-json.png?branch=master)](https://travis-ci.org/cblage/elixir-json)

This library provides a natively implemented JSON encoder and decoder for Elixir.

All contributions are welcome.

# Examples

```elixir
  JSON.encode([result: "this will be a elixir result"])
  "{\"result\":\"this will be a elixir result\"}"
```

```elixir
  JSON.decode("{\"result\":\"this will be a elixir result\"}")
  {:ok, [result: "this will be a elixir result"]}
```

# License
The Elixir JSON library is available under the [BSD 3-Clause aka "BSD New" license](http://www.tldrlegal.com/l/BSD3)
