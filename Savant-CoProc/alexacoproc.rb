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
configxml = (File.join(File.dirname(File.expand_path(__FILE__)), 'serviceImplementation.xml')) if uselocalxmlfile

# Lets get the services xml file loaded
servicesdoc = Document.new(File.new(configxml))

# Start building the zones and resources
servicesdoc.each_element('//zone') do |zone|
    # Skip if this is not a user zone
    next if zone.attributes['type'] != 'user'
    liveservices[zone.attributes['name']] = {}

    zone.each_element('service') do |services|
        # We only want enabled services
        next unless services.attributes['enabled'] == 'true'
        commands = {}
        if services.attributes['service_type'] == 'SVC_GEN_GENERIC'
            # Iterate over the custom workflows created. Only store workflows enabled on the UI.
            services.each_element('requests/request') do |request|
                next unless request.attributes['show_request_in_uis'] == 'true'
                commands[request.attributes['name']] = zone.attributes['name']+'-'+services.attributes['source_component_name']+'-'+services.attributes['source_logical_component']+'-'+services.attributes['variant_id']+'-'+services.attributes['service_type']+'='+request.attributes['name']
            end
        elsif services.attributes['service_type'] == 'SVC_ENV_AV_DOORBELL'
            # We cant do anything with the doorbell service so we need to ignore it
            next
        # In the future I might break this out to define individual services like SatelliteTV and control channel changes etc..
        elsif services.attributes['service_type'].start_with?('SVC_AV_')
            commands['Turn On'] = zone.attributes['name']+'-'+services.attributes['source_component_name']+'-'+services.attributes['source_logical_component']+'-'+services.attributes['variant_id']+'-'+services.attributes['service_type']+'-PowerOn'
            # I think I will try move this to the zone level... rather than have one for each service
            #commands['PowerOff'] = zone.attributes['name']+'-----PowerOff'
        else
            # This is not a supported service so we want to skip it.
            next
        end

        # Add the commands list if there are commands available
        liveservices[zone.attributes['name']][services.attributes['service_alias']] = commands if commands.size > 0

    end
end

# Display the completed array. This is for testing only
puts liveservices
