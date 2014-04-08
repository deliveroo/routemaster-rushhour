require 'sinatra'
require 'json'

module Routemaster
  class Blackhole < Sinatra::Base
    post '/events' do
      events = JSON.parse(request.body)
      puts "received #{events.length} events"
      halt :ok
    end
  end
end


