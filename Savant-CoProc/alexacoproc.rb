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

# Setup some environment variables to start with (defaulted for Pro host)
testing = false
servicelimit = 65
scli = '~/Applications/RacePointMedia/sclibridge '
servicefile = 'userConfig.rpmConfig/serviceImplementation.xml'
configxml = '/Users/RPM/Library/Application Support/RacePointMedia/' + servicefile
liveservices = {"uuid" => SecureRandom.uuid, "devices" => {}}

# Check to see if we are running on a linux host, if so we need to change the variables
platform = RUBY_PLATFORM
if platform.include? 'linux'
  scli = '/usr/local/bin/sclibridge '
  configxml = '/data/RPM/GNUstep/Library/ApplicationSupport/RacePointMedia/' + servicefile
end

# # For some reason, things break when I read the UUID from a file.. no idea why at this point
# # Get our UUID. If no file exists, create it
# uuidfile = (File.join(File.dirname(File.expand_path(__FILE__)), 'uuid.cfg'))
# if File.exist? uuidfile
#   file = File.open(uuidfile, "r")
#   uuid = file.read
# else
#   uuid =  SecureRandom.uuid
#   out_file = File.new("uuid.cfg", "w")
#   out_file.puts(uuid)
#   out_file.close
# end
# liveservices["uuid"] = uuid.to_s

# Announce we have started and are processing services
$stdout.print "Processing available services in current config. This could take some time depending on the number of zones and services available.\n"

# Load a local file. This is for testing and will only load if the file exists
if File.exist? (File.join(File.dirname(File.expand_path(__FILE__)), 'serviceImplementation.xml'))
  $stdout.print "Using local service file\n"
  testing = true
  configxml = (File.join(File.dirname(File.expand_path(__FILE__)), 'serviceImplementation.xml'))
end

# Lets get the services xml file loaded
servicesdoc = Document.new(File.new(configxml))

# Service index
servicenumber = 1

# Start building the zones and resources
servicesdoc.each_element('//zone') do |zone|
  # Skip if this is not a user zone
  next if zone.attributes['type'] != 'user'

  zone.each_element('service') do |services|
    # We only want enabled services
    next unless services.attributes['enabled'] == 'true'
    racepointservices = {}
    if services.attributes['service_type'] == 'SVC_GEN_GENERIC'
      # Iterate over the custom workflows created. Only use workflows enabled on the UI.
      services.each_element('requests/request') do |request|
        if servicenumber < servicelimit
          next unless request.attributes['show_request_in_uis'] == 'true'
          turnon = zone.attributes['name']+'-'+services.attributes['source_component_name']+'-'+services.attributes['source_logical_component']+'-'+services.attributes['variant_id']+'-'+services.attributes['service_type']+'-'+request.attributes['name']
          # I need to figure a way to deal with on/off custom workflows...
          turnoff = turnon
          liveservices['devices'][servicenumber] = {"name" => request.attributes['name'], "type" => 'savant_service', "poweron" => scli + "servicerequestcommand '" + turnon + "'", "poweroff" => scli + "servicerequestcommand '" + turnoff + "'"}
          servicenumber += 1
        end
      end
    elsif services.attributes['service_type'] == 'SVC_ENV_AV_DOORBELL'
      # We cant do anything with the doorbell service so we need to ignore it
      next
    elsif services.attributes['service_type'].start_with?('SVC_AV_')
      racepointservices['Turn On'] = zone.attributes['name']+'-'+services.attributes['source_component_name']+'-'+services.attributes['source_logical_component']+'-'+services.attributes['variant_id']+'-'+services.attributes['service_type']+'-PowerOn'
      racepointservices['Turn Off'] = zone.attributes['name']+'-'+services.attributes['source_component_name']+'-'+services.attributes['source_logical_component']+'-'+services.attributes['variant_id']+'-'+services.attributes['service_type']+'-PowerOff'

      # limit removed for now... it seems to be working fine now.
      if servicenumber < servicelimit
        unless racepointservices['Turn On'].nil?
          liveservices['devices'][servicenumber] = {"name" => services.attributes['service_alias'] + ' ' + zone.attributes['name'], "type" => 'savant_service', "poweron" => scli + "servicerequestcommand '" + racepointservices['Turn On'] + "'", "poweroff" => scli + "servicerequestcommand '" + racepointservices['Turn Off'] + "'"}
          servicenumber += 1
        end
      end
    else
      # This is not a supported service so we want to skip it.
      next
    end
  end
end

## Start of Philips Hue Emulator
##
# If the IP address is not passed by command line, we need to detect, and set it
if settings.bind == 'localhost'
  ip = Socket.ip_address_list.detect { |intf| intf.ipv4_private? }
  set :bind, "#{ip.ip_address}"
end

# Convert our service list into devices
Device.options = liveservices['device_settings']
devices = {}
liveservices['devices'].each { |key, data|
  devices[key.to_s] = Device.create data
}

# print out the devices list, should be removed for production
if testing
  $stdout.print 'Found ' + devices.count.to_s + " things to enable\n"
  $stdout.print 'UUID = ' + liveservices['uuid'] + "\n"
end

# Start web server for discovery and command captures
server = SSDPServer.new settings.bind, settings.port, liveservices['uuid']
server.start

# Handle the different http requests
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
  content_type :json
  {}.to_json
end

get '/description.xml' do
  content_type 'text/xml'
  erb :description, :locals => {:addr => settings.bind, :port => settings.port, :udn => liveservices['uuid']}
end