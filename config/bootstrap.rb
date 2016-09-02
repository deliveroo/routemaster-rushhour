File.expand_path('../..', __FILE__).tap { |d| $:.unshift(d) unless $:.include?(d) }
require 'dotenv'

Dotenv.load!

