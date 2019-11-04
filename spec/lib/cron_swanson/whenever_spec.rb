require 'spec_helper'
require 'whenever'

RSpec.describe CronSwanson::Whenever do
  subject { CronSwanson::Whenever.new(Whenever::JobList.new('')) }

  describe '#initialize' do
    it 'raises an error if not given a job list' do
      expect {
        CronSwanson::Whenever.new('foo')
      }.to raise_error(ArgumentError, /supply a Whenever::JobList/)
    end

    it 'accepts a seed parameter' do
      subject = CronSwanson::Whenever.new(Whenever::JobList.new(''), seed: 'test-seed')
      expect(subject.seed).to eq 'test-seed'
    end
  end

  describe '#add' do
    it 'raises an error if not given a block' do
      expect {
        subject.add
      }.to raise_error(ArgumentError, 'provide a block containing jobs to schedule.')
    end

    it 'schedules a daily job by default' do
      schedule_rb_contents = <<-EOF
        swanson = CronSwanson::Whenever.new(self)
        swanson.add do
          rake 'test:job'
        end
      EOF

      job_list = Whenever::JobList.new(schedule_rb_contents)
      output = job_list.generate_cron_output

      expect(output).to match(/^21 8 \* \* \*.*rake test:job/)
    end

    it 'schedules a job at the given interval' do
      schedule_rb_contents = <<-EOF
        swanson = CronSwanson::Whenever.new(self)
        swanson.add(interval: 60 * 60 * 4) do
          rake 'test:job'
        end
      EOF

      job_list = Whenever::JobList.new(schedule_rb_contents)
      output = job_list.generate_cron_output

      expect(output).to match(/^23 1,5,9,13,17,21 \* \* \*.*rake test:job/)
    end

    it 'understands ActiveSupport::Duration instances for interval parameter' do
      schedule_rb_contents = <<-EOF
        swanson = CronSwanson::Whenever.new(self)
        swanson.add(interval: 4.hours) do
          rake 'test:job'
        end
      EOF

      job_list = Whenever::JobList.new(schedule_rb_contents)
      output = job_list.generate_cron_output

      expect(output).to match(/^23 1,5,9,13,17,21 \* \* \*.*rake test:job/)
    end

    it 'schedules multiple jobs in the same block at the same time' do
      schedule_rb_contents = <<-EOF
        swanson = CronSwanson::Whenever.new(self)
        swanson.add do
          rake 'test:job'
          rake 'other:job'
        end
      EOF

      job_list = Whenever::JobList.new(schedule_rb_contents)
      output = job_list.generate_cron_output

      expect(output).to match(/^41 13 \* \* \*.*rake test:job/)
      expect(output).to match(/^41 13 \* \* \*.*rake other:job/)
    end

    it 'schedules multiple add blocks at distinct times based on their contents' do
      schedule_rb_contents = <<-EOF
        swanson = CronSwanson::Whenever.new(self)
        swanson.add do
          rake 'test:job'
        end

        swanson.add do
          rake 'other:job'
        end
      EOF

      job_list = Whenever::JobList.new(schedule_rb_contents)
      output = job_list.generate_cron_output

      expect(output).to match(/^21 8 \* \* \*.*rake test:job/)
      expect(output).to match(/^33 15 \* \* \*.*rake other:job/)
    end

    it 'understands custom job types' do
      schedule_rb_contents = <<-EOF
        swanson = CronSwanson::Whenever.new(self)
        job_type :ron, '/usr/bin/ron :task'

        swanson.add do
          ron 'bacon whiskey'
        end
      EOF

      job_list = Whenever::JobList.new(schedule_rb_contents)
      output = job_list.generate_cron_output

      expect(output).to match(/^28 20 \* \* \*.*\/usr\/bin\/ron bacon whiskey/)
    end

    it 'raises if a job type is unknown' do
      schedule_rb_contents = <<-EOF
        swanson = CronSwanson::Whenever.new(self)
        swanson.add do
          unknown_job_type
        end
      EOF

      expect {
        Whenever::JobList.new(schedule_rb_contents)
      }.to raise_error 'unknown_job_type is not defined. Call `job_type` to resolve this.'
    end

    it 'passes roles option along to whenever' do
      schedule_rb_contents = <<-EOF
        swanson = CronSwanson::Whenever.new(self)
        swanson.add do
          rake 'all_roles'
        end

        swanson.add(roles: [:a]) do
          rake 'a_only'
        end

        swanson.add(roles: [:b]) do
          rake 'b_only'
        end
      EOF

      job_list = Whenever::JobList.new(string: schedule_rb_contents, roles: [:a])
      output = job_list.generate_cron_output
      expect(output).to match(/^24 21 \* \* \*.*rake all_roles/)
      expect(output).to match(/^15 11 \* \* \*.*rake a_only/)
      expect(output).not_to match(/b_only/)

      job_list = Whenever::JobList.new(string: schedule_rb_contents, roles: [:b])
      output = job_list.generate_cron_output
      expect(output).to match(/^24 21 \* \* \*.*rake all_roles/)
      expect(output).to match(/^18 18 \* \* \*.*rake b_only/)
      expect(output).not_to match(/a_only/)
    end

    it 'varies scheduling for the same job when given a different seed' do
      seeds = ['a', 'b']
      output = []
      seeds.each do |seed|
        schedule_rb_contents = <<-EOF
          swanson = CronSwanson::Whenever.new(self, seed: '#{seed}')
          swanson.add do
            rake 'test:job'
          end
        EOF
        job_list = Whenever::JobList.new(schedule_rb_contents)
        output << job_list.generate_cron_output
      end

      expect(output[0]).to match(/^43 14/)
      expect(output[1]).to match(/^12 8/)
    end
  end

  describe 'method_missing shenanigans' do
    it 'should raise an error if invoked outside of an #add call' do
      expect {
        subject.rake
      }.to raise_error 'CronSwanson::Whenever#method_missing invoked outside of CronSwanson::Whenever#add'
    end
  end
end
