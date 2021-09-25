# EscalatingLogger

EscalatingLogger is a transparent subclass of Ruby's Logger that automatically
increases log verbosity as the number of ERRORs logged exceeds a given rate 
threshold. The intent is to get more log detail when things are going wrong,
and less log noise when everything is going right.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'escalating_logger'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install escalating_logger

## Usage

Use it anywhere you use [Logger](https://github.com/ruby/logger).
EscalatingLogger maintains the same interface as `Logger`, so it's safe
to use as a drop-in replacement. Note that EscalatingLogger is slower than
Logger, so keep the performance hit in mind (see [Benchmarks](##benchmarks))

## Benchmarks

TL;DR using EscalatingLogger is 16% slower than Logger :not-bad:

```ruby
require 'logger'
require_relative 'lib/escalating_logger'
require 'benchmark/ips'

Benchmark.ips do |x|
  x.report("using Logger") { logger.error "test" }  
  x.report("using EscalatingLogger") { escalating_logger.error "test" }  
  x.compare!  
end  
Warming up --------------------------------------
        using Logger    12.996k i/100ms
using EscalatingLogger
                        11.267k i/100ms
Calculating -------------------------------------
        using Logger    122.641k (±16.3%) i/s -    597.816k in   5.070444s
using EscalatingLogger
                        100.404k (±15.2%) i/s -    495.748k in   5.078565s

Comparison:
          using Logger:   122641.3 i/s
using EscalatingLogger:   100403.5 i/s - same-ish: difference falls within error
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/alexdglover/escalating_logger.


## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
