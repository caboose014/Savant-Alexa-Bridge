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
    puts "+==================="
    puts zone.attributes["name"]
    liveservices[zone.attributes["name"]] = {}

    zone.each_element("service") do |service|
        next unless service.attributes["service_type"].start_with?("SVC_AV_", "SVC_ENV_") && service.attributes["enabled"] == "true"
        next if service.attributes["service_type"] == "SVC_ENV_AV_DOORBELL"

        puts service.attributes["service_alias"]
    end
end

puts liveservices
