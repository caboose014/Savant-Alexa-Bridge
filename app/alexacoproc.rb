#!/usr/bin/env ruby


# Process command line switches
# This has to be put in before the 'require sinatra' otherwise sinatra grabs the arguments
require 'optparse'
args = {}
OptionParser.new do |arg|
  arg.on('-z','--zone_name x,y,z', Array, 'Comma separated zones to limit discovery to') { |o| args[:zone_name] = o }
  arg.on('-p','--port_number=val', Integer, 'Specify a custom port (default is 4567)') { |o| args[:port_number] = o }
  arg.on('-l','--service_limit=val', Integer, 'Limit the number of services/workflows to be discovered') { |o| args[:service_limit] = o }
  arg.on('-r','--remove_zone', 'Remove the zone name from the service name') { |o| args[:remove_zone] = o }
end.parse!

# requires
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
scli = '~/Applications/RacePointMedia/sclibridge '
servicefile = 'userConfig.rpmConfig/serviceImplementation.xml'
configxml = '/Users/RPM/Library/Application Support/RacePointMedia/' + servicefile
liveservices = {"uuid" => SecureRandom.uuid, "devices" => {}}

# Define maximum services to discover
if args.key?(:service_limit)
  servicelimit = args[:service_limit]
else
  servicelimit = 65
end

# Set custom port if defined
if args.key?(:port_number)
  set :port, args[:port_number]
end

# Check to see if we are running on a linux host, if so we need to change the variables
platform = RUBY_PLATFORM
if platform.include? 'linux'
  scli = '/usr/local/bin/sclibridge '
  configxml = '/data/RPM/GNUstep/Library/ApplicationSupport/RacePointMedia/' + servicefile
end

# Get our UUID. If no file exists, create it and populate a uuid
# If a custom port is used, leave the random UUID
unless args.key?(:port_number)
  uuidfile = (File.join(File.dirname(File.expand_path(__FILE__)), 'uuid.cfg'))
  if File.exist? uuidfile
    file = File.open(uuidfile, 'r')
    uuid = file.read
  else
    uuid =  SecureRandom.uuid
    out_file = File.new('uuid.cfg', 'w')
    out_file.puts(uuid)
    out_file.close
  end
  liveservices['uuid'] = uuid.gsub("\n",'')
end
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

  # If we have specified zones, see if this is one of them or move on
  if args.key?(:zone_name)
    next unless args[:zone_name].include?(zone.attributes['name'])
  end

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
          if args.key?(:remove_zone)
            add_zone_name = ''
          else
            add_zone_name = ' ' + zone.attributes['name']
          end
          liveservices['devices'][servicenumber] = {"name" => services.attributes['service_alias'] + add_zone_name, "type" => 'savant_service', "poweron" => scli + "servicerequestcommand '" + racepointservices['Turn On'] + "'", "poweroff" => scli + "servicerequestcommand '" + racepointservices['Turn Off'] + "'"}
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