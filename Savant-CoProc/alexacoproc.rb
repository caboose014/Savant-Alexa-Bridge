#!/usr/bin/env ruby

require 'socket'
require 'net/http'


scli = "~/Applications/RacePointMedia/sclibridge "
configxml = "/Users/RPM/Library/Application Support/RacePointMedia/userConfig.rpmConfig/serviceImplementation.xml"
platform = RUBY_PLATFORM
if platform.include? "linux"
    scli = "/usr/local/bin/sclibridge "
    rpmconfig = Dir["/data/RPM/GNUstep/Library/ApplicationSupport/RacePointMedia/*.rpmConfig"]
    configxml = "/data/RPM/GNUstep/Library/ApplicationSupport/RacePointMedia/"
end
