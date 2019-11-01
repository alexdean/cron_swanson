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

    it 'schedules a job daily by default' do
      schedule_rb_contents = <<-EOF
        CronSwanson::Whenever.add(self) do
          rake 'test:job'
        end
      EOF

      job_list = Whenever::JobList.new(schedule_rb_contents)
      output = job_list.generate_cron_output

      expect(output).to match(/^38 2 \* \* \*.*rake test:job/)
    end

    it 'can schedule multiple jobs like normal whenever can' do
      schedule_rb_contents = <<-EOF
        CronSwanson::Whenever.add(self) do
          rake 'test:job'
          rake 'other:job'
        end
      EOF

      job_list = Whenever::JobList.new(schedule_rb_contents)
      output = job_list.generate_cron_output

      expect(output).to match(/^38 2 \* \* \*.*rake test:job/)
      expect(output).to match(/^38 2 \* \* \*.*rake other:job/)
    end

    it 'schedules multiple add blocks at distinct times' do
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

      expect(output).to match(/^38 2 \* \* \*.*rake test:job/)
      expect(output).to match(/^54 19 \* \* \*.*rake other:job/)
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

      expect(output).to match(/^18 7 \* \* \*.*\/usr\/bin\/ron bacon whiskey/)
    end
  end
end
