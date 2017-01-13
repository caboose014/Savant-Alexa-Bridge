#!/usr/bin/env ruby

require 'rubygems'
require 'securerandom'
require 'sinatra'
require 'yaml'
require 'json'

require_relative 'lib/init'

if settings.bind == 'localhost'
  puts "IP address not supplied, use -o command line option"
  exit
end

options = YAML.load_file('alexa.yaml')
puts options
Device.options = options["device_settings"]

devices = {}
options['devices'].each { |key, data|
  devices[key.to_s] = Device.create data
}

server = SSDPServer.new settings.bind, settings.port, options['uuid']
server.start

put '/api/:userId/lights/:lightId/state' do
  device = devices[params['lightId']]
  content_type :json
  if device
    body = JSON.parse(request.body.read)
    state = body['on']
    device.set_state(state)
    [{
      "success" => {
        "/lights/#{params['lightId']}/state/on" => state
      }
    }].to_json
  else
    [{
      "error" => {
        "type" => 3,
        "address" => "/lights/#{params['lightId']}",
        "description" => "resource, /lights/80, not available"
      }
    }].to_json
  end
  
end

get '/api/:userId/lights/:lightId' do
  content_type :json
  devices[params['lightId']].to_json
end

get '/api/:userId/lights' do
  content_type :json
  devices.to_json
end

# get '/api/:userId/groups/:groupId' do
#   puts "Requested Group"
#   content_type :json
#   {}.to_json
# end

get '/api/:userId' do
  puts "Request all the Stuffs"
  content_type :json
  {}.to_json
end


get '/description.xml' do
  content_type 'text/xml'
  erb :description, :locals => { :addr => settings.bind, :port => settings.port, :udn => options['uuid'] }
end