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

`CronSwanson::Whenever.add` will calculate a run time for jobs by hashing the text
of the job definitions in the given block.

**NOTE**: This means that if you change the jobs in the block, you will also change the schedule time
for these jobs.

#### Daily

```ruby
# in config/schedule.rb
CronSwanson::Whenever.add(self) do
  rake 'sample:job'
end
```

This will result in `rake sample:job` being scheduled once per day, at a time
determined by `CronSwanson`.

#### Multiple times/day

```ruby
# in config/schedule.rb

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

Any custom job types which have been defined will work.

```ruby
# in config/schedule.rb
job_type :ron, '/usr/bin/ron :task'

CronSwanson::Whenever.add(self) do
  ron 'bacon whiskey'
end
```

#### roles

Roles are supported. See the [whenever documentation](https://github.com/javan/whenever#capistrano-roles)
for more information on this.

```ruby
CronSwanson::Whenever.add(self) do
  rake 'will_run_on_all_roles'
end

# will only be added to servers with the :restricted role
CronSwanson::Whenever.add(self, roles: [:restricted]) do
  rake 'restricted_only'
end
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/alexdean/cron_swanson.
