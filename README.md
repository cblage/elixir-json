# Elixir JSON

[![Build Status](https://travis-ci.org/cblage/elixir-json.svg?branch=develop)](https://travis-ci.org/cblage/elixir-json) [![Hex.pm](https://img.shields.io/hexpm/dt/json.svg?style=flat-square)](https://hex.pm/packages/json) [![Test Coverage](https://api.codeclimate.com/v1/badges/43b6e8c25e036558ccb6/test_coverage)](https://codeclimate.com/github/cblage/elixir-json/test_coverage) [![Hex.pm](https://img.shields.io/hexpm/v/json.svg?style=flat-square)](https://hex.pm/packages/json) [![Inline docs](http://inch-ci.org/github/cblage/elixir-json.svg)](http://inch-ci.org/github/cblage/elixir-json)
                                                                                                                                     
This library provides a natively implemented JSON encoder and decoder for Elixir.

All contributions are welcome.

# Before you install

When dealing with smaller `file.json ~ 14KB` payloads, `JSON v1` handles the processing consistently performant, with
 a much smaller deviation, and absolutely no real-world absolute performance differences with `Jason`.

However, with often unusually large `file.json > 5MB` payloads, and if the processing speed for those payloads is 
paramount to you (ie, processing them in a real-time manner vs using them in migration scripts or whatever), `JSON v1` 
currently significantly slower when compared to `Jason`.

#### Small payload `bench/data/utf-8-unescaped.json < 30KB` benchmark results for `JSON v1` and `Jason`

As you can see below, both libraries handle "regular" small `json` payloads beautifully.

`JSON.decode` calls while usually being a bit slower than their `Jason` counterparts, they are more consistently 
performant, with a much smaller deviation. 

So I would actually advise using `JSON.decode` and `JSON.encode` for smaller payloads.

For `JSON.encode` vs `Jason.encode`, the difference is so minimal, it's not worth arguing about. 

| Library        	| Average  	| Deviation 	| median   	| minimum  	| maximum   	|
|----------------	|----------	|-----------	|----------	|----------	|-----------	|
| `JSON.decode`  	| 13.35 ms 	| ±45.95%   	| 11.47 ms 	| 8.17 ms  	| 99.49 ms  	|
| `Jason.decode` 	| 0.26 ms  	| ±246.84%  	| 0.170 ms 	| 0.150 ms 	| 64.35 ms  	|
| `JSON.encode`  	| 1.32 ms  	| ±225.81%  	| 0.58 ms  	| 0.28 ms  	| 103.70 ms 	|
| `Jason.encode` 	| 0.30 ms  	| ±316.71%  	| 0.163 ms 	| 0.147 ms 	| 82.68 ms  	|

#### Full `benchee` reports for `bench/data/utf-8-unescaped.json < 30KB`:
 - `decode`: https://bit.ly/2GVV8dy
 - `encode`: https://bit.ly/2v5W0H0


#### Large payload `bench/data/issue-90.json ~ 8MB` benchmark results for `JSON v1` and `Jason`

However, with often unusually large `file.json > 5MB` payloads, and if the processing speed for those payloads is paramount to you 
(ie, processing them in a real-time manner vs using them in migration scripts or whatever), then 
`JSON v1` would not be the best choice when compared to `Jason`.

| Library        	| Average  	| Deviation 	| median   	| minimum  	| maximum   	|
|----------------	|----------	|-----------	|----------	|----------	|-----------	|
| `JSON.decode`  	| 8.93 s	| ±5.71%	 	| 8.96 s 	| 8.10 s  	| 9.57 s	  	|
| `Jason.decode` 	| 0.182 s	| ±21.60%		| 0.171 s	| 0.139 s 	| 0.42 s	  	|
| `JSON.encode`  	| 5.51 s	| ±18.10%	  	| 5.24 s 	| 4.32 s 	| 7.36 s 	    |
| `Jason.encode` 	| 0.186 s 	| ±26.41%   	| 0.173 s	| 0.122 s	| 0.38 s	  	|

### Full `benchee` reports for `bench/data/issue-90.json ~ 8MB`:
 - `decode`: https://bit.ly/2HxReEP
 - `encode`: https://bit.ly/2HuR0OM

# Plan of action for `Elixir JSON v2`

I am currently working on a solution for this problem in `JSON v2`.
You can follow the process here: https://github.com/cblage/elixir-json/pull/52 

# Interim Solution

To processes these large payloads adding the `Jason` lib to your dependencies (without hopefully removing `JSON` 
for the smaller payloads :sweat_smile:): 
 - `Jason@Hex.pm`: http://hex.pm/packages/jason
 - `Jason@GitHub`: https://github.com/michalmuskala/jason
 
After installing `Jason`, you then use `JSON.decode` and `JSON.encode` for small your small `30KB range json` payloads due to the reasons mentioned above.

While `Elixir JSON v2` is not ready to processs the bigger `>5MB json` payloads in time-sensitive operations, you go for `Jason.decode` and `Jason.encode`.

Thanks for the comprehension,
Carlos Brito Lage

## Example 

```elixir
 [
   {:cowboy, "~> 1.0.0"},
   {:plug, "~> 1.0"},
   {:json, "~> 1.2"},
   {:jason, "~> 1.0"},
 ]
```

You can find its documentation here: https://hexdocs.pm/jason/readme.html

# Before you install

When dealing with smaller `file.json ~ 14KB` payloads, `JSON v1` handles the processing consistently performant, with
 a much smaller deviation, and absolutely no real-world absolute performance differences with `Jason`.

However, with often unusually large `file.json > 5MB` payloads, and if the processing speed for those payloads is 
paramount to you (ie, processing them in a real-time manner vs using them in migration scripts or whatever), `JSON v1` 
currently significantly slower when compared to `Jason`.

#### Small payload `bench/data/utf-8-unescaped.json < 30KB` benchmark results for `JSON v1` and `Jason`

As you can see below, both libraries handle "regular" small `json` payloads beautifully.

`JSON.decode` calls while usually being a bit slower than their `Jason` counterparts, they are more consistently 
performant, with a much smaller deviation. 

So I would actually advise using `JSON.decode` and `JSON.encode` for smaller payloads.

For `JSON.encode` vs `Jason.encode`, the difference is so minimal, it's not worth arguing about. 

| Library        	| Average  	| Deviation 	| median   	| minimum  	| maximum   	|
|----------------	|----------	|-----------	|----------	|----------	|-----------	|
| `JSON.decode`  	| 13.35 ms 	| ±45.95%   	| 11.47 ms 	| 8.17 ms  	| 99.49 ms  	|
| `Jason.decode` 	| 0.26 ms  	| ±246.84%  	| 0.170 ms 	| 0.150 ms 	| 64.35 ms  	|
| `JSON.encode`  	| 1.32 ms  	| ±225.81%  	| 0.58 ms  	| 0.28 ms  	| 103.70 ms 	|
| `Jason.encode` 	| 0.30 ms  	| ±316.71%  	| 0.163 ms 	| 0.147 ms 	| 82.68 ms  	|

#### Full `benchee` reports for `bench/data/utf-8-unescaped.json < 30KB`:
 - `decode`: https://bit.ly/2GVV8dy
 - `encode`: https://bit.ly/2v5W0H0


#### Large payload `bench/data/issue-90.json ~ 8MB` benchmark results for `JSON v1` and `Jason`

However, with often unusually large `file.json > 5MB` payloads, and if the processing speed for those payloads is paramount to you 
(ie, processing them in a real-time manner vs using them in migration scripts or whatever), then 
`JSON v1` would not be the best choice when compared to `Jason`.

| Library        	| Average  	| Deviation 	| median   	| minimum  	| maximum   	|
|----------------	|----------	|-----------	|----------	|----------	|-----------	|
| `JSON.decode`  	| 8.93 s	| ±5.71%	 	| 8.96 s 	| 8.10 s  	| 9.57 s	  	|
| `Jason.decode` 	| 0.182 s	| ±21.60%		| 0.171 s	| 0.139 s 	| 0.42 s	  	|
| `JSON.encode`  	| 5.51 s	| ±18.10%	  	| 5.24 s 	| 4.32 s 	| 7.36 s 	    |
| `Jason.encode` 	| 0.186 s 	| ±26.41%   	| 0.173 s	| 0.122 s	| 0.38 s	  	|

### Full `benchee` reports for `bench/data/issue-90.json ~ 8MB`:
 - `decode`: https://bit.ly/2HxReEP
 - `encode`: https://bit.ly/2HuR0OM

# Plan of action for `Elixir JSON v2`

I am currently working on a solution for this problem in `JSON v2`.
You can follow the process here: https://github.com/cblage/elixir-json/pull/52 

# Interim Solution

To processes these large payloads adding the `Jason` lib to your dependencies (without hopefully removing `JSON` 
for the smaller payloads :sweat_smile:): 
 - `Jason@Hex.pm`: http://hex.pm/packages/jason
 - `Jason@GitHub`: https://github.com/michalmuskala/jason
 
After installing `Jason`, you then use `JSON.decode` and `JSON.encode` for small your small `30KB range json` payloads due to the reasons mentioned above.

While `Elixir JSON v2` is not ready to processs the bigger `>5MB json` payloads in time-sensitive operations, you go for `Jason.decode` and `Jason.encode`.

Thanks for the comprehension,
Carlos Brito Lage

## Example 

```elixir
 [
   {:cowboy, "~> 1.0.0"},
   {:plug, "~> 1.0"},
   {:json, "~> 1.2"},
   {:jason, "~> 1.0"},
 ]
```

You can find its documentation here: https://hexdocs.pm/jason/readme.html

# Installing

Simply add ```{:json, "~> 1.2"}``` to your project's ```mix.exs``` file, in the dependencies list and run ```mix deps.get json```.

## Example for a project that already uses [Plug](https://github.com/elixir-plug/plug):

```elixir
[
  {:cowboy, "~> 1.0.0"},
  {:plug, "~> 1.0"},
  {:json, "~> 1.2"},
]
```

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

# License
The Elixir JSON library is available under the [BSD 3-Clause aka "BSD New" license](http://www.tldrlegal.com/l/BSD3)
