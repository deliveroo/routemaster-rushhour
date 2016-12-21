require 'routemaster/client'

module RushHour
  module BusConnection
    protected

    def _bus
      @@_bus ||= Routemaster::Client.new(
        url:  ENV.fetch('BUS_URL'),
        uuid: ENV.fetch('PUBLISHER_UUID'),
        timeout: 10,
      )
    end
  end
end
