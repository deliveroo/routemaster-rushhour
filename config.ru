require 'routemaster/receiver'
require 'dotenv'
require 'sinatra'
require 'pry'

Dotenv.load!

class Handler
  def on_events(events)
    events.each do |event|
      event.keys.each { |k| event[k.to_sym] = event.delete(k) }
      $stdout.write("%<topic>-12s %<type>-12s %<url>s %<t>s\n" % event)
      $stdout.flush
    end
  end
end

use Rack::Auth::Basic do |username, password|
  username == ENV['CLIENT_UUID']
end

use Routemaster::Receiver, {
  path:    '/events',
  uuid:    'demo',
  handler: Handler.new
}

run Sinatra::Base
