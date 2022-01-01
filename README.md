# CronSwanson

`CronSwanson` helps distribute schedule cron jobs.

![Never half-ass two things.](whole-ass.jpg)

If you've ever had load spikes when many applications all starting the same
cron job at the same time, `CronSwanson` can help you.

The library generates crontab schedule strings which are consistent (they aren't
random) but which are fuzzed/shifted depending on some input.

## Build Status

[![Test Suite](https://github.com/alexdean/cron_swanson/actions/workflows/rspec.yml/badge.svg)](https://github.com/alexdean/cron_swanson/actions/workflows/rspec.yml)

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

### build_schedule

Use `build_schedule` to build a cron schedule string. The supplied string is hashed
to determine the run time of the job.

```ruby
CronSwanson.build_schedule 'whiskey'
#=> "33 18 * * *"
```

**To keep two applications running the same job from executing at once**, make the
application name part of the build_schedule key.

```ruby
CronSwanson.build_schedule 'application-a whiskey'
#=> "4 19 * * *"

CronSwanson.build_schedule 'application-b whiskey'
#=> "11 7 * * *"
```

An `interval` (in seconds) can be supplied if you want a job to be run more than
once/day. This `interval` must be a factor of 24 hours.

```ruby
CronSwanson.build_schedule 'bacon', interval: 60 * 60 * 4
#=> "26 2,6,10,14,18,22 * * *"
```

You can also use `ActiveSupport::Duration` instances.

```ruby
CronSwanson.build_schedule 'bacon', interval: 4.hours
#=> "26 2,6,10,14,18,22 * * *"
```

### Whenever Integration

`CronSwanson` is built to integrate with the fantastic [whenever](https://github.com/javan/whenever) gem.

`#schedule` will calculate a run time for jobs by hashing the text of the job
definitions in the given block. (Plus an optional seed string if one is supplied.)

**NOTE**: This means that if you change the jobs in the block, or the seed, you will also
change the schedule time for these jobs.

#### Daily

```ruby
# in config/build_schedule.rb
swanson = CronSwanson::Whenever.new(self, seed: 'application-name')
swanson.schedule do
  rake 'sample:job'
end
```

This will result in `rake sample:job` being scheduled once per day, at a time
determined by `CronSwanson`.

#### Multiple times/day

```ruby
# in config/build_schedule.rb

# with ActiveSupport
swanson = CronSwanson::Whenever.new(self, seed: 'application-name')
swanson.schedule(interval: 4.hours) do
  rake 'sample:job'
end

# without ActiveSupport
swanson = CronSwanson::Whenever.new(self, seed: 'application-name')
swanson.schedule(interval: 60 * 60 * 4) do
  rake 'sample:job'
end
```

#### job types

Any custom job types which have been defined will work.

```ruby
# in config/build_schedule.rb
job_type :ron, '/usr/bin/ron :task'

swanson = CronSwanson::Whenever.new(self, seed: 'application-name')
swanson.schedule do
  ron 'bacon whiskey'
end
```

#### roles

Roles are supported. See the [whenever documentation](https://github.com/javan/whenever#capistrano-roles)
for more information on this.

```ruby
swanson = CronSwanson::Whenever.new(self, seed: 'application-name')
swanson.schedule do
  rake 'will_run_on_all_roles'
end

# Added to servers with the :restricted role
swanson.schedule(roles: [:restricted]) do
  rake 'restricted_only'
end
```

#### seeds

Varying the seed string affects all jobs scheduled by that instance.

```ruby
swanson = CronSwanson::Whenever.new(self, seed: 'application-a')
swanson.schedule do
  rake 'job'
end

swanson = CronSwanson::Whenever.new(self, seed: 'application-b')
swanson.schedule do
  rake 'job'
end
```

In this example, the job being scheduled is the same, but the schedule times will
be different because the seed string is different.

## Development

After checking out the repo, run `bin/setup` to install dependencies. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/alexdean/cron_swanson.
