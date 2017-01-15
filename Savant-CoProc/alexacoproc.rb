#!/usr/bin/env ruby

require 'socket'
require 'net/http'
require 'rexml/document'
require 'json'
require 'sinatra'
require 'rubygems'
require 'securerandom'
include REXML
require_relative 'lib/init'


# This should be set to false for production
uselocalxmlfile = true

# Setup some environment variables to start with
scli = '~/Applications/RacePointMedia/sclibridge '
servicefile = 'userConfig.rpmConfig/serviceImplementation.xml'
configxml = '/Users/RPM/Library/Application Support/RacePointMedia/' + servicefile
liveservices = {"uuid"=>"744d903d-e8ad-4b64-9711-5b733e1c5d71", "devices"=>{}}

# Check to see if we are running on a linux host, if so we need to change the variables
platform = RUBY_PLATFORM
if platform.include? 'linux'
    scli = '/usr/local/bin/sclibridge '
    configxml = '/data/RPM/GNUstep/Library/ApplicationSupport/RacePointMedia/' + servicefile
end
# Local file for testing
# configxml = (File.join(File.dirname(File.expand_path(__FILE__)), 'serviceImplementation.xml')) if uselocalxmlfile

# Lets get the services xml file loaded
servicesdoc = Document.new(File.new(configxml))

# Service index
servicenumber = 1

# Start building the zones and resources
servicesdoc.each_element('//zone') do |zone|
    # Skip if this is not a user zone
    next if zone.attributes['type'] != 'user'

    # liveservices[zone.attributes['name']] = {}

    zone.each_element('service') do |services|
        # We only want enabled services
        next unless services.attributes['enabled'] == 'true'
        commands = {}
        if services.attributes['service_type'] == 'SVC_GEN_GENERIC'
            # Iterate over the custom workflows created. Only store workflows enabled on the UI.
            services.each_element('requests/request') do |request|
                next unless request.attributes['show_request_in_uis'] == 'true'
                # commands[request.attributes['name']] = zone.attributes['name']+'-'+services.attributes['source_component_name']+'-'+services.attributes['source_logical_component']+'-'+services.attributes['variant_id']+'-'+services.attributes['service_type']+'='+request.attributes['name']
            end
        elsif services.attributes['service_type'] == 'SVC_ENV_AV_DOORBELL'
            # We cant do anything with the doorbell service so we need to ignore it
            next
        # In the future I might break this out to define individual services like SatelliteTV and control channel changes etc..
        elsif services.attributes['service_type'].start_with?('SVC_AV_')
            commands['Turn On'] = zone.attributes['name']+'-'+services.attributes['source_component_name']+'-'+services.attributes['source_logical_component']+'-'+services.attributes['variant_id']+'-'+services.attributes['service_type']+'-PowerOn'
            commands['Turn Off'] = zone.attributes['name']+'-'+services.attributes['source_component_name']+'-'+services.attributes['source_logical_component']+'-'+services.attributes['variant_id']+'-'+services.attributes['service_type']+'-PowerOff'
            # I think I will try move this to the zone level... rather than have one for each service
            #commands['PowerOff'] = zone.attributes['name']+'-----PowerOff'
        else
            # This is not a supported service so we want to skip it.
            next
        end

        # Add the commands list if there are commands available
        # liveservices[zone.attributes['name']][services.attributes['service_alias']] = commands if commands.size > 0

        # Only allow a maximum number of services, not sure if there is a limit or not yet
        if servicenumber < 30
            if !commands['Turn On'].nil?
              liveservices['devices'][servicenumber] = {"name"=>services.attributes['service_alias'] + " " + zone.attributes['name'], "type"=>"savant_service", "poweron"=>scli + "servicerequestcommand '" + commands['Turn On'] + "'", "poweroff"=>scli + "servicerequestcommand '" + commands['Turn Off'] + "'"}
              servicenumber += 1
            end
        end
    end
end

# To be removed at production time
# puts liveservices

## Start of Philips Hue Emulator

if settings.bind == 'localhost'
  ip = Socket.ip_address_list.detect{|intf| intf.ipv4_private?}
  set :bind, "#{ip.ip_address}"
end

options = liveservices
Device.options = options["device_settings"]

devices = {}
options['devices'].each { |key, data|
  devices[key.to_s] = Device.create data
}

puts devices

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