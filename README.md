# EscalatingLogger

EscalatingLogger is a transparent subclass of Ruby's Logger that automatically
increases/decreases log verbosity based on the rate of `ERROR` messages being
logged. The intent is to get more log detail when things are going wrong,
and less log noise (and less log costs) when everything is going right.

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
Logger, so keep the performance hit in mind (see [Benchmarks](#benchmarks))

## Demo

The example below is simply for demonstration purposes. You should choose
higher values for rate limiting for smoother changing of verbosity.

```ruby
class Tester
  def initialize
    @logger = EscalatingLogger::Logger.new(STDOUT, initial_token_count: 5, refill_rate: 1, max_token_count: 10, level: Logger::ERROR)
  end

  def method_that_triggers_escalation
    @logger.debug('starting method method_that_triggers_escalation')
    @logger.info('this thing happened')
    @logger.warn('heads up, this might be a problem')
    @logger.error('error - something broke!')
  end

  def method_that_only_warns
    @logger.debug('starting method method_that_logs_warn')
    @logger.info('this thing happened')
    @logger.warn('heads up, this might be a problem')
  end
end

t = Tester.new

# Cause logger to become more verbose by logging lots of errors
(1..50).each do |i|
  t.method_that_triggers_escalation
  sleep 0.2
end
```

Running the example above, you'll see that initially only the `ERRORs` are
logged. As more and more `ERROR`s are logged, EscalatingLogger changes the
verbosity or `level` of the logger, causing `WARN` messages to appear, then
`INFO` messages, and finally `DEBUG` messages.

Note that this is based on the _rate_ of `ERROR` messages, not just the raw
count. In the example above, the code is logging one `ERROR` message every 0.2
seconds, but the token bucket is only refilling at the rate of 1 token per
second. Therefore, logging gets continually more verbose until it hits the
`max_verbosity` specified (defaults to `Logger::DEBUG`).

If the rate of `ERROR` messages falls below the refill rate of the token
bucket, eventually log verbosity will decrease. Try the example below
(a continuation of the earlier code block):

```ruby
# As rate of error logs decreases, verbosity will decrease
(1..100).each do |i|
  t.method_that_only_warns
  sleep 0.2
end
```

You'll notice that as time progresses, `DEBUG` stop getting logged, then
`INFO` stop getting logged, and finally the `WARN` messages disappear and
nothing is being logged. The minimum verbosity can be controlled with the
`min_verbosity` parameter (defaults to `Logger::ERROR`).

## Tuning token bucket settings

In a real world situation, the `initial_token_count` and
`max_token_count` should be much larger values. Note that the token bucket
acts as a two-sided rate limiter - if there are zero tokens remaining in the
bucket, then the error rate has been too high for too long and verbosity should
be increased. If number of tokens is equal to the maximum token count, then the
error rate has been exceedingly low for too long and verbosity should be
decreased.

Because of this two-sided nature, you can control how sensitive the logger is
to errors. In a balanced case, `max_token_count` would be twice the value of
the `initial_token_count`. This results in balanced behavior. For example,
with `initial_token_count = 100`, `max_token_count = 200`, and
`refill_rate = 1`, then any error rate resulting in 101 or more tokens being
used per 100 seconds would increase the verbosity. Similarly, any error rate
resulting in 99 or less tokens being used per 100 seconds would decrease the
verbosity.

If you want your logger to be more sensitive to `ERROR` messages and decrease
verbosity more slowly, skew your `initial_token_count` closer to zero than the
`max_token_count`. For example, `initial_token_count = 50` and
`max_token_count = 200` would increase verbosity faster, but decreasing
verbosity would be slower.

Finally, note that the rate limiting comes from a
[token bucket](https://en.wikipedia.org/wiki/Token_bucket) implementation
from [bozos_buckets](https://github.com/alexdglover/bozos_buckets/). This means
the time window is not fixed, and bursting is supported. For example, with a
`refill_rate = 1` and `initial_token_count = 100`, this would allow 1 error per
second for 100 seconds, 50 errors per second for 2 seconds, or 100 errors per
second for 1 second before increasing verbosity.

## Benchmarks

TL;DR using EscalatingLogger is ~18% slower than Logger :not-bad:

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
