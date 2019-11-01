require "cron_swanson/version"
require "cron_swanson/whenever"
require 'digest/sha2'

# CronSwanson is a utility to generate run times for cron jobs which are
# regular, but which vary per job.
module CronSwanson
  SECONDS_PER_HOUR = 60 * 60
  SECONDS_PER_DAY = SECONDS_PER_HOUR * 24

  def self.default_interval
    SECONDS_PER_DAY
  end

  # offset within a time period
  #
  # if the interval is 6 hours, the returned offset will be some number of seconds
  # from 0 to 6 hours.
  #
  # @param [String] job_identifier
  #   if nil, method will determine this on its own
  # @param [Integer] interval how often will the job be run?
  # @return [Integer] number of seconds to offset this job
  def self.offset(job_identifier, interval: default_interval)
    sha = Digest::SHA256.hexdigest(job_identifier.to_s)

    # largest possible hex sha256 value
    max_sha256_value = (16**64).to_f

    # what % of the max sha256 is the current app?
    sha_pct_of_max_sha256 = sha.to_i(16) / max_sha256_value

    # apply that same % to the desired interval to get an offset
    offset_seconds = (sha_pct_of_max_sha256 * interval).round

    offset_seconds
  end

  def self.schedule(job_identifier, interval: default_interval)
    if interval > SECONDS_PER_DAY
      raise ArgumentError, "interval must be less than 1 day (#{SECONDS_PER_DAY} seconds)."
    end

    if SECONDS_PER_DAY % interval != 0
      raise ArgumentError, "A day (#{SECONDS_PER_DAY} seconds) must be evenly " \
        "divisible by the given interval."
    end

    # figure out how many times job will happen in a day
    runs_per_day = SECONDS_PER_DAY / interval

    # raise if runs_per_day has a decimal component.

    run_at = Time.at(offset(job_identifier, interval: interval)).utc

    hours = []
    runs_per_day.times do |i|
      hours << run_at.hour + (i * interval / SECONDS_PER_HOUR)
    end

    "#{run_at.min} #{hours.join(',')} * * *"
  end
end
