require "cron_swanson/version"
require "cron_swanson/whenever"
require 'digest/sha2'

# CronSwanson is a utility to generate run times for cron jobs which are
# regular, but which vary per job.
module CronSwanson
  SECONDS_PER_MINUTE = 60
  SECONDS_PER_HOUR = SECONDS_PER_MINUTE * 60
  SECONDS_PER_DAY = SECONDS_PER_HOUR * 24

  def self.default_interval
    SECONDS_PER_DAY
  end

  # offset within a time period
  #
  # if the interval is 6 hours, the returned offset will be some number of seconds
  # between 0 and 60 * 60 * 6 seconds (6 hours).
  #
  # @param [String] job_identifier
  #   if nil, method will determine this on its own
  # @param [Integer] interval how often will the job be run?
  # @return [Integer] number of seconds to offset this job
  def self.offset(job_identifier, interval: default_interval)
    sha = Digest::SHA256.hexdigest(job_identifier.to_s)

    # largest possible hex sha256 value
    max_sha256_value = (16**64).to_f

    # what % of the max sha256 is the job_identifier?
    sha_pct_of_max_sha256 = sha.to_i(16) / max_sha256_value

    # apply that same % to the desired interval to get an offset
    offset_seconds = (sha_pct_of_max_sha256 * interval).round

    offset_seconds
  end

  # generate a cron schedule string
  #
  # the same input will always produce the same output.
  #
  # @param [String] job_identifier a job to generate a schedule for
  # @param [Integer, ActiveSupport::Duration] interval how often should the job
  #   be scheduled to run?
  # @return [String] a schedule string like '38 4 * * *'
  def self.build_schedule(job_identifier, interval: default_interval)
    if interval > SECONDS_PER_DAY
      raise ArgumentError, "interval must be less than 1 day (#{SECONDS_PER_DAY} seconds)."
    end

    if SECONDS_PER_DAY % interval != 0
      raise ArgumentError, "A day (#{SECONDS_PER_DAY} seconds) must be evenly " \
        "divisible by the given interval."
    end

    job_offset = offset(job_identifier, interval: interval)

    if interval >= SECONDS_PER_HOUR
      # figure out how many times job will happen in a day
      runs_per_day = SECONDS_PER_DAY / interval

      run_at = Time.at(job_offset).utc
      hours = []
      runs_per_day.times do |i|
        hours << run_at.hour + (i * interval / SECONDS_PER_HOUR)
      end

      "#{run_at.min} #{hours.join(',')} * * *"
    else
      minutes = []

      job_offset_minutes = job_offset / SECONDS_PER_MINUTE
      interval_minutes = interval / SECONDS_PER_MINUTE

      runs_per_hour = SECONDS_PER_HOUR / interval
      runs_per_hour.times do |i|
        puts "job_offset:#{job_offset} i:#{i} interval:#{interval}"
        minutes << job_offset_minutes + (i * interval_minutes)
      end

      "#{minutes.join(',')} * * * *"
    end
  end
end
