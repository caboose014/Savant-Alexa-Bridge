require 'ssdp'

class SSDPServer
  
  def initialize(addr, port, uuid)
    @server = SSDP::Producer.new :respond_to_all => true
    @server.uuid = uuid
    
    ssdp_options = {
      "CACHE-CONTROL" => "max-age=100",
      "LOCATION" => "http://#{addr}:#{port}/description.xml",
      "ST" => "upnp:rootdevice",
      "EXT" => "",
      "SERVER" =>  "FreeRTOS/7.4.2, UPnP/1.0, IpBridge/1.7.0"
    }

    
    @server.add_service("urn:Belkin:device:**", ssdp_options)
  end
  
  def start
    @server.start
  end
  
end