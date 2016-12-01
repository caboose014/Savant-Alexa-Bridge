#!/usr/bin/env ruby

require 'socket'
require 'net/http'
require 'rexml/document'
include REXML

# Setup some environment variables to start with
scli = "~/Applications/RacePointMedia/sclibridge "
servicefile = "userConfig.rpmConfig/serviceImplementation.xml"
configxml = "/Users/RPM/Library/Application Support/RacePointMedia/" + servicefile
liveservices = {}

# Check to see if we are running on a linux host, if so we need to change the variables
platform = RUBY_PLATFORM
if platform.include? "linux"
    scli = "/usr/local/bin/sclibridge "
    configxml = "/data/RPM/GNUstep/Library/ApplicationSupport/RacePointMedia/" + servicefile
end

# Temp for testing
configxml = (File.join(File.dirname(File.expand_path(__FILE__)), "serviceImplementation.xml"))

# Lets get the services xml file loaded
servicesdoc = Document.new(File.new(configxml))

# Start building the zones and resources
servicesdoc.each_element("//zone") do |zone|
    # Skip if this is not a user zone
    next if zone.attributes["type"] != "user"
    liveservices[zone.attributes["name"]] = {}

    zone.each_element("service") do |services|
        next unless services.attributes["service_type"].start_with?("SVC_AV_") && services.attributes["enabled"] == "true"
        next if services.attributes["service_type"] == "SVC_ENV_AV_DOORBELL"

        commands = {}
        commands["PowerOn"] = zone.attributes["name"]+"-"+services.attributes["source_component_name"]+"-"+services.attributes["source_logical_component"]+"-"+services.attributes["variant_id"]+"-"+services.attributes["service_type"]+"-PowerOn"
        commands["PowerOff"] = zone.attributes["name"]+"-----PowerOff"

        liveservices[zone.attributes["name"]][services.attributes["service_alias"]] = commands
    end
end

puts liveservices
