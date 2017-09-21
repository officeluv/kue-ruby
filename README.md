# kue-ruby
Ruby interface gem for the [Automattic Kue][0] Redis store

## Usage

```ruby
kue = KueRuby.new(redis: Redis.new)
job = kue.create_job(type: 'foobar', data: { foo: 2 })
jobp = kue.create_job(type: 'foobaz', data: { foo: 2 }, priority: -1, max_attempts: 3)
job.max_attempts = 5
job = job.save kue.redis
```

Right now, this gem only supports creating jobs in Kue. Feel free to contribute with more!

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'kue_ruby'
```

And then execute:

```sh
$ bundle install
```

Or install it yourself as:

```sh
$ gem install kue_ruby
```

## Testing

```sh
$ rspec
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/officeluv/kue_ruby. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

[0]: https://github.com/Automattic/kue
