require 'net/http'
require 'json'

class Device
  DEVICES = {}
  @options = {}

  class << self
    attr_accessor :options
  end

  def self.register_device name
    DEVICES[name] = self
  end

  def self.create (data)
    device_class = DEVICES[data['type']]
    if device_class
      device_class.new data
    end
  end

  def initialize(data)
    @name = data["name"]
    @state = false
  end

  def to_json(*a)
    {
      "manufacturername" => "Philips",
      "modelid" => "LWB006",
      "name" => @name,
      "pointsymbol" => {  "1" => "none", "2" => "none", "3" => "none", "4" => "none", "5" => "none", "6" => "none", "7" => "none", "8" => "none" },
      "state" => { "alert" => "none", "bri" => 254, "on" => @state, "reachable" => true },
      "swversion" => "5.38.2.19136",
      "type" => "Dimmable Light"
    }.to_json(*a)
  end

  def set_state(state)
    @state = state
  end
end

# class OpenHABDevice < Device
#   register_device "openhab"
#
#   def initialize(data)
#     super data
#     @key = data['key']
#     @http = Net::HTTP.new(Device.options['openhab']['host'], Device.options['openhab']['port'])
#   end
#
#   def set_state(state)
#     super state
#     request = Net::HTTP::Get.new("/CMD?#{@key}=#{state ? "ON" : "OFF"}")
#     @http.request(request)
#   end
# end

# class HueScene < Device
#   register_device "hue_scene"
#
#   def initialize(data)
#     super data
#     @group = data['group']
#     @scene = data['scene']
#     @appid = Device.options['hue']['appid']
#     @http = Net::HTTP.new(Device.options['hue']['host'])
#   end
#
#   def set_state(state)
#     super state
#     if state
#       req = Net::HTTP::Put.new("/api/#{@appid}/groups/#{@group}/action")
#       req.body = { "scene" => @scene }.to_json
#       resp = @http.request(req)
#     end
#   end
# end

# class DomoticzSwitch < Device
#     register_device "domoticz_switch"
#
#     def initialize(data)
#         super data
#         @idx = data['idx']
#         @http = Net::HTTP.new(Device.options['domoticz']['host'], Device.options['domoticz']['port'])
#     end
#
#     def set_state(state)
#         super state
#         request = Net::HTTP::Get.new("/json.htm?type=command&param=switchlight&idx=#{@idx}&switchcmd=#{state ? "On" : "Off"}")
#         resp = @http.request(request)
#     end
# end

class SavantService < Device
    register_device("savant_service")

    def initialize(data)
        super data
        @poweron = data['poweron']
        @poweroff = data['poweroff']
    end

    def set_state(state)
        super state
        if state
            puts @poweron
        else
            puts @poweroff
        end
    end

end