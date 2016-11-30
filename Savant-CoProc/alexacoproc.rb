#!/usr/bin/env ruby

require 'socket'
require 'net/http'
require 'rexml/document'
include REXML

# Setup some environment variables to start with
scli = "~/Applications/RacePointMedia/sclibridge "
servicefile = "userConfig.rpmConfig/serviceImplementation.xml"
configxml = "/Users/RPM/Library/Application Support/RacePointMedia/" + servicefile

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
    next if zone.attributes["type"] == "resource"
    puts zone.attributes["name"]
end
