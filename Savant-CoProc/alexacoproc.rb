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
        # We only want enabled services
        next unless services.attributes["enabled"] == "true"
        commands = {}
        if services.attributes["service_type"] == "SVC_GEN_GENERIC"
            # Itterate over the custom workflows created. Only store workflows enabled on the UI.
            services.each_element("requests/request") do |request|
                next unless request.attributes["show_request_in_uis"] == "true"
                commands[request.attributes["name"]] = zone.attributes["name"]+"-"+services.attributes["source_component_name"]+"-"+services.attributes["source_logical_component"]+"-"+services.attributes["variant_id"]+"-"+services.attributes["service_type"]+"="+request.attributes["name"]
            end
        elsif services.attributes["service_type"] == "SVC_ENV_AV_DOORBELL"
            next
        elsif services.attributes["service_type"].start_with?("SVC_AV_")
            commands["PowerOn"] = zone.attributes["name"]+"-"+services.attributes["source_component_name"]+"-"+services.attributes["source_logical_component"]+"-"+services.attributes["variant_id"]+"-"+services.attributes["service_type"]+"-PowerOn"
            #commands["PowerOff"] = zone.attributes["name"]+"-----PowerOff"
        else
            next
        end

        # Add the commands list if there are commands available
        liveservices[zone.attributes["name"]][services.attributes["service_alias"]] = commands if commands.size > 0

    end
end

puts liveservices
