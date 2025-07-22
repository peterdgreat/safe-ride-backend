class RideUpdatedChannel < ApplicationCable::Channel
  def subscribed
    stream_from "ride_#{params[:ride_id]}"
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end
end
