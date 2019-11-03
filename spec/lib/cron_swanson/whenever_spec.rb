require 'spec_helper'
require 'whenever'

RSpec.describe CronSwanson::Whenever do
  describe '.add' do
    it 'raises an error if not given a job list' do
      expect {
        CronSwanson::Whenever.add(:foo)
      }.to raise_error(ArgumentError, /supply a Whenever::JobList/)

    end

    it 'raises an error if not given a block' do
      job_list = Whenever::JobList.new('')

      expect {
        CronSwanson::Whenever.add(job_list)
      }.to raise_error(ArgumentError, 'provide a block containing jobs to schedule.')
    end

    it 'schedules a daily job by default' do
      schedule_rb_contents = <<-EOF
        CronSwanson::Whenever.add(self) do
          rake 'test:job'
        end
      EOF

      job_list = Whenever::JobList.new(schedule_rb_contents)
      output = job_list.generate_cron_output

      expect(output).to match(/^27 12 \* \* \*.*rake test:job/)
    end

    it 'schedules a job at the given interval' do
      schedule_rb_contents = <<-EOF
        CronSwanson::Whenever.add(self, interval: 60 * 60 * 4) do
          rake 'test:job'
        end
      EOF

      job_list = Whenever::JobList.new(schedule_rb_contents)
      output = job_list.generate_cron_output

      expect(output).to match(/^4 2,6,10,14,18,22 \* \* \*.*rake test:job/)
    end

    it 'understands ActiveSupport::Duration instances for interval parameter' do
      schedule_rb_contents = <<-EOF
        CronSwanson::Whenever.add(self, interval: 4.hours) do
          rake 'test:job'
        end
      EOF

      job_list = Whenever::JobList.new(schedule_rb_contents)
      output = job_list.generate_cron_output

      expect(output).to match(/^4 2,6,10,14,18,22 \* \* \*.*rake test:job/)
    end

    it 'schedules multiple jobs in the same block at the same time' do
      schedule_rb_contents = <<-EOF
        CronSwanson::Whenever.add(self) do
          rake 'test:job'
          rake 'other:job'
        end
      EOF

      job_list = Whenever::JobList.new(schedule_rb_contents)
      output = job_list.generate_cron_output

      expect(output).to match(/^28 3 \* \* \*.*rake test:job/)
      expect(output).to match(/^28 3 \* \* \*.*rake other:job/)
    end

    it 'schedules multiple add blocks at distinct times based on their contents' do
      schedule_rb_contents = <<-EOF
        CronSwanson::Whenever.add(self) do
          rake 'test:job'
        end

        CronSwanson::Whenever.add(self) do
          rake 'other:job'
        end
      EOF

      job_list = Whenever::JobList.new(schedule_rb_contents)
      output = job_list.generate_cron_output

      expect(output).to match(/^27 12 \* \* \*.*rake test:job/)
      expect(output).to match(/^58 22 \* \* \*.*rake other:job/)
    end

    it 'understands custom job types' do
      schedule_rb_contents = <<-EOF
        job_type :ron, '/usr/bin/ron :task'

        CronSwanson::Whenever.add(self) do
          ron 'bacon whiskey'
        end
      EOF

      job_list = Whenever::JobList.new(schedule_rb_contents)
      output = job_list.generate_cron_output

      expect(output).to match(/^6 20 \* \* \*.*\/usr\/bin\/ron bacon whiskey/)
    end

    it 'raises if a job type is unknown' do
      schedule_rb_contents = <<-EOF
        CronSwanson::Whenever.add(self) do
          unknown_job_type
        end
      EOF

      expect {
        Whenever::JobList.new(schedule_rb_contents)
      }.to raise_error 'unknown_job_type is not defined. Call `job_type` to resolve this.'
    end

    it 'passes roles option along to whenever' do
      schedule_rb_contents = <<-EOF
        CronSwanson::Whenever.add(self) do
          rake 'all_roles'
        end

        CronSwanson::Whenever.add(self, roles: [:a]) do
          rake 'a_only'
        end

        CronSwanson::Whenever.add(self, roles: [:b]) do
          rake 'b_only'
        end
      EOF

      job_list = Whenever::JobList.new(string: schedule_rb_contents, roles: [:a])
      output = job_list.generate_cron_output
      expect(output).to match(/^19 9 \* \* \*.*rake all_roles/)
      expect(output).to match(/^59 7 \* \* \*.*rake a_only/)
      expect(output).not_to match(/b_only/)

      job_list = Whenever::JobList.new(string: schedule_rb_contents, roles: [:b])
      output = job_list.generate_cron_output
      expect(output).to match(/^19 9 \* \* \*.*rake all_roles/)
      expect(output).to match(/^47 17 \* \* \*.*rake b_only/)
      expect(output).not_to match(/a_only/)
    end
  end
end
