# Docker::Rainbow

This gem implements a scheme for choosing terse but meaningful names of Docker
containers. The names that it chooses convey information about when and how
containers were deployed, and how they relate to one another, without resorting
to unreadable random gobbledegook for names.

(If you want random gobbledegook, you should refer to containers by their IDs,
which are globally unique. Names are there to make the operator's life easier
by giving her a way to refer to containers when she types docker CLI commands.)

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'docker-rainbow'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install docker-rainbow

## Usage

There is no command-line interface to the rainbow. Its API is minimal and
hopefully self-documenting.

```ruby
require 'docker/rainbow'

rainbow = Docker::Rainbow.new()

# The color will be one of "blue," "green," "purple," etc. We try to find a
# color that isn't in use, but wrap around when necessary.
puts "Launching containers for the #{rainbow.color} epoch"

# This will return an Array like so:
#  ['blue_cassandra_1', 'blue_cassandra_2', 'blue_cassandra_3']
names = rainbow.name_containers('spotify/cassandra:latest', count:3)


names.each do |name|
  system("docker run --name #{name} spotify/cassandra:latest")
end
```

### Reusing names

By default, the rainbow raises an exception if it tries to choose any name
that is already in use by any container, running _or_ exited. Because rainbow's
palette has just six colors, this will typically happen after just a few
deploys.

In most cases, by the time we wrap back around to a previous color, the original
containers will have exited long ago; it's unlikely that you will have six
"vintages" of a given service running at the same time. For this reason the
rainbow will automatically remove exited containers with conflicting names,
unless you specify `gc:false` when you build your rainbow.

```ruby
  rainbow.name_containers('spotify/cassandra:latest', gc:false)
```

However: if any container with a conflicting name is *still running*, this
counts as a conflict and the rainbow will raise an exception because in all
likelihood, something is seriously wrong with the containers deployed to this
box. (How often would you have six different revisions of software running
on one box at once time?)

If you will handle naming conflicts yourself, you can ask the rainbow to ignore
them and/or opt out of the built-in garbage collection.

```ruby
  rainbow.name_containers('spotify/cassandra:latest', reuse:true, gc:false)
```

### Accounting for entrypoints

For images that expose an `ENTRYPOINT` rather than a `CMD`, you might end up
with several long-lived containers launched from the same base image but with
conceptually different purposes. You can tell the rainbow the name of the
command you will be passing to `docker run` in order to choose unambiguous
names.

Note that you don't need to use the verbatim command; you could use a nickname
for the "role" of the container.

```ruby
  rainbow.name_containers('docker/swarm', cmd: 'manager')
    # => ["blue_swarm_manager"]

  rainbow.name_containers('docker/swarm', cmd: 'node', count:2)
    # => ["blue_swarm_node_1", "blue_swarm_node_2"]
```

We **strongly encourage** you to use a terse, meaningful description of the
cmd instead of passing the entire command word-for-word into the rainbow. You
might find it super interesting that you invoked busybox as `/bin/sh -c ls foo`,
but the people who look at `docker ps` output probably don't care to see a
container named `busybox_bin-sh-c-ls-foo`!

To encourage you to choose terse names, Rainbow will extract the _first_
alphanumeric word from the cmd and use it alone as a suffix for your container
named. If this is an issue, refer to "Customizing Container Names", below.

### Multi-tenancy

You might be deploying containers to a cluster that is in use by other tenants;
in this case, you want to choose a unique prefix to indicate which tenant owns
which container. Rainbow borrows from the nomenclature used by `docker-compose`
and supports an optional *project name* for all of your containers.

```ruby
  rainbow = Docker::Rainbow.new(project: 'development')

  rainbow.name_containers('foo') # => ["development_blue_foo]
```

## Customizing Container Names

If you absolutely insist on having more colors, you can pass a custom
palette.

```ruby
  Docker::Rainbow.new(palette: ['mauve', 'pink', 'chartreuse', ...])
```

You can also subclass Rainbow and override its private methods if you want
to be more opinionated about naming choices.

```ruby
  class PedanticRainbow < Docker::Rainbow
    # Our full command is relevant to the container's personality; include
    # every word, not just the first word! Also use periods to separate
    # command words, not hyphens.
    private def cmd_suffix(cmd)
      cmd.split(/[^A-Za-z0-9]+/).join('.')
    end
  end
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/xeger/docker-rainbow. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](contributor-covenant.org) code of conduct.

