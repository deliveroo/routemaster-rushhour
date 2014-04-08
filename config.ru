require 'app'

use Rack::Auth::Basic do |username, password|
  username == ENV['CLIENT_UUID']
end

run Routemaster::Blackhole
