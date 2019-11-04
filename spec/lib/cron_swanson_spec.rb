require 'spec_helper'

RSpec.describe CronSwanson do
  describe '.offset' do
    it 'generates an offset based on the given job name' do
      expect(CronSwanson.offset('test_job')).to eq 17569
    end

    it 'always generates an offset which is between 0 and the given interval' do
      [100, 1000, 10_000].each do |interval|
        offset = CronSwanson.offset('test_job', interval: interval)
        expect(offset < interval).to eq true
        expect(offset >= 0).to eq true
      end
    end
  end

  describe '.build_schedule' do
    it 'raises an error if interval is greater than 24 hours' do
      expect {
        CronSwanson.build_schedule('test_job', interval: CronSwanson::SECONDS_PER_DAY * 2)
      }.to raise_error 'interval must be less than 1 day (86400 seconds).'
    end

    it 'raises an error if interval is not a factor of 24 hours' do
      expect {
        CronSwanson.build_schedule('test_job', interval: 61)
      }.to raise_error 'A day (86400 seconds) must be evenly divisible by the given interval.'
    end

    describe 'without a specified interval' do
      it 'creates a cron-compatible build_schedule string for a daily job' do
        expect(CronSwanson.build_schedule('test_job')).to eq "52 4 * * *"
      end
    end

    describe 'with a specified interval' do
      it 'creates cron-compatible build_schedule strings for the specified intervals' do
        six_hours = 60 * 60 * 6
        expect(CronSwanson.build_schedule('test_job',       interval: six_hours)).to eq "13 1,7,13,19 * * *" # rubocop:disable Metrics/LineLength
        expect(CronSwanson.build_schedule('other_test_job', interval: six_hours)).to eq "24 0,6,12,18 * * *" # rubocop:disable Metrics/LineLength

        twelve_hours = 60 * 60 * 12
        expect(CronSwanson.build_schedule('test_job',       interval: twelve_hours)).to eq "26 2,14 * * *"
        expect(CronSwanson.build_schedule('other_test_job', interval: twelve_hours)).to eq "48 0,12 * * *"
      end
    end
  end
end
