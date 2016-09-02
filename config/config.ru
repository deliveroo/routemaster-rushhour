require_relative 'bootstrap'
require 'routemaster/receiver'
require 'sinatra/base'
require 'rush_hour/event_handler'

Wisper.subscribe(RushHour::EventHandler.new, prefix: true)

use Routemaster::Receiver, {
  path:    '/events',
  uuid:    ENV.fetch('BUS_UUID', 'demo'),
}
run Sinatra::Base.new
