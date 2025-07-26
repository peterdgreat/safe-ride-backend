require 'rails_helper'

RSpec.describe SendSmsJob, type: :job do
  include ActiveJob::TestHelper

  it 'enqueues the job' do
    expect { SendSmsJob.perform_later('recipient', 'message') }
      .to have_enqueued_job(SendSmsJob)
      .with('recipient', 'message')
      .on_queue('default')
  end

  it 'sends the SMS message' do
    log_output = StringIO.new
    original_logger = Rails.logger
    Rails.logger = Logger.new(log_output)

    SendSmsJob.perform_now('recipient', 'message')

    Rails.logger = original_logger # Restore original logger

    expect(log_output.string).to include("Sending SMS to recipient: message")
  end
end