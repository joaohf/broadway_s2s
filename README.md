# BroadwaySQS

A NiFi connector for [Broadway](https://github.com/joaohf/broadway_s2s).

Documentation can be found at [https://hexdocs.pm/broadway_s2s](https://hexdocs.pm/broadway_s2s).

## Installation

Add `:broadway_s2s` to the list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:broadway_s2s, "~> 0.1.0"}
  ]
end
```

## Usage

Configure Broadway with one or more producers using `BroadwayS2S.Producer`:

```elixir
Broadway.start_link(MyBroadway,
  name: MyBroadway,
  producer: [
    module: {BroadwayS2S.Producer,
          [
             hostname: "localhost",
             port: 8080,
             port_id: "NiFi input or output port",
             local_network_interface: "lo0"
          ]
    }
  ]
)
```

## License

[MIT](https://spdx.org/licenses/MIT.html) 