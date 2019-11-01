# CronSwanson

`CronSwanson` helps schedule cron jobs.

![Never half-ass two things.](whole-ass.jpg)

If you've ever had load spikes when many applications all starting the same
cron job at the same time, `CronSwanson` can help you.

The library generates crontab schedule strings which are consistent (they aren't
random) but which are fuzzed/shifted depending on some input.

## Build Status

[![Build Status](https://travis-ci.org/alexdean/cron_swanson.svg?branch=master)](https://travis-ci.org/alexdean/cron_swanson)

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'cron_swanson'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install cron_swanson

## Usage

### schedule

Use `schedule` to build a cron schedule. The supplied string is hashed to determine
the run time of the job.

```ruby
CronSwanson.schedule 'whiskey'
#=> "33 18 * * *"
```

**To keep two applications running the same job from executing at once**, make the
application name part of the schedule key.

```ruby
CronSwanson.schedule 'application-a whiskey'
#=> "4 19 * * *"

CronSwanson.schedule 'application-b whiskey'
#=> "11 7 * * *"
```

An `interval` (in seconds) can be supplied if you want a job to be run more than
once/day. This `interval` must be a factor of 24 hours.

```ruby
CronSwanson.schedule 'bacon', interval: 60 * 60 * 4
#=> "26 2,6,10,14,18,22 * * *"
```

You can also use `ActiveSupport::Duration` instances.

```ruby
CronSwanson.schedule 'bacon', interval: 4.hours
#=> "26 2,6,10,14,18,22 * * *"
```

### Whenever Integration

`CronSwanson` is built to integrate with the fantastic [whenever](https://github.com/javan/whenever) gem.

#### Daily

```ruby
# in the config/schedule.rb file
CronSwanson::Whenever.add(self) do
  rake 'sample:job'
end
```

This will result in `rake sample:job` being scheduled once per day, at a time
determined by `CronSwanson`.

#### Multiple times/day

```ruby
# in the config/schedule.rb file

# with ActiveSupport
CronSwanson::Whenever.add(self, interval: 4.hours) do
  rake 'sample:job'
end

# without ActiveSupport
CronSwanson::Whenever.add(self, interval: 60 * 60 * 4) do
  rake 'sample:job'
end
```

#### job types

The block is evaluated by `whenever`, so any custom job types will work.

```ruby
# in config/schedule.rb
job_type :ron, '/usr/bin/ron :task'

CronSwanson::Whenever.add(self) do
  ron 'bacon whiskey'
end
```

#### Limitation

The whenever integration code currently derives a scheduled time from the source
location of the `add` call. This means that moving the `.add` invocation to
a different line in schedule.rb will cause it to be run at a different time.

This limitation exists because I (currently) don't know of a way to inspect
the contents of a block at runtime. If a way to do this can be found, I
would prefer to calculate the time based on the block's contents.

## Development

After checking out the repo, run `bin/setup` to install dependencies. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/alexdean/cron_swanson.
