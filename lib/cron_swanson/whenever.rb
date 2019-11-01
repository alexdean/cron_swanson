module CronSwanson
  # integration for the whenever gem: https://github.com/javan/whenever
  module Whenever
    # CronSwanson integration for whenever
    #
    # The given block can use any job types understood by your whenever configuration.
    # See https://github.com/javan/whenever#define-your-own-job-types.
    #
    # CronSwanson currently uses the location it is invoked from in schedule.rb
    # to calculate a job time. This means that moving the `.add` invocation to
    # a different line in schedule.rb will cause it to be run at a different time.
    #
    # This limitation exists because I (currently) don't know of a way to inspect
    # the contents of a block at runtime. If a way to do this can be found, I
    # would prefer to calculate the time based on the block's contents.
    #
    # @example run a job once/day
    #   # in the config/schedule.rb file
    #   CronSwanson::Whenever.add(self) do
    #     rake 'job'
    #   end
    #
    # @example run a job four times daily
    #   # in the config/schedule.rb file
    #
    #   # with ActiveSupport
    #   CronSwanson::Whenever.add(self, interval: 4.hours) do
    #     rake 'job'
    #   end
    #
    #   # without ActiveSupport
    #   CronSwanson::Whenever.add(self, interval: 60 * 60 * 4) do
    #     rake 'job'
    #   end
    #
    # @param [Whenever::JobList] whenever_job_list For code in `config/schedule.rb`
    #   this can be referred to as `self`.
    # @param [Integer] interval how many seconds do you want between runs of this job
    def self.add(whenever_job_list, interval: CronSwanson.default_interval, &block)
      if !whenever_job_list.is_a?(::Whenever::JobList)
        raise ArgumentError, "supply a Whenever::JobList. (In schedule.rb code, use `self`.)"
      end

      raise ArgumentError, "provide a block containing jobs to schedule." if !block_given?

      # TODO: ideally we'd hash the contents of the block, not the location it was defined at
      schedule = CronSwanson.schedule(block.source_location, interval: interval)
      whenever_job_list.every(schedule, &Proc.new)
    end
  end
end
