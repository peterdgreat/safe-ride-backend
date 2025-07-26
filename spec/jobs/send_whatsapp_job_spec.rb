require 'rails_helper'

RSpec.describe SendWhatsappJob, type: :job do
  include ActiveJob::TestHelper

  it 'enqueues the job' do
    expect { SendWhatsappJob.perform_later('recipient', 'message') }
      .to have_enqueued_job(SendWhatsappJob)
      .with('recipient', 'message')
      .on_queue('default')
  end

  it 'sends the WhatsApp message' do
    log_output = StringIO.new
    original_logger = Rails.logger
    Rails.logger = Logger.new(log_output)

    SendWhatsappJob.perform_now('recipient', 'message')

    Rails.logger = original_logger # Restore original logger

    expect(log_output.string).to include("Sending WhatsApp to recipient: message")
  end
end