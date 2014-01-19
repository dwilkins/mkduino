module Mkduino
  class Probe
    attr_accessor :options
    attr_accessor :probe_options

    DEVICES = ["/dev/ttyUSB0",
               "/dev/ttyUSB1",
               "/dev/ttyUSB2",
               "/dev/ttyACM0",
               "/dev/ttyACM1",
               "/dev/ttyACM2",
               "/dev/rfcomm0",
               "/dev/rfcomm1",
               "/dev/rfcomm2"]

    BOARDS = {
      "mega" => {
        variant: "mega",
        clock_speed: 16000000,
        device: "/dev/ACM0",
        baud_rate: "115200",
        programmer: "stk500",
        mcu: "atmega2560"
      },
      "mega1280" => {
        variant: "mega",
        clock_speed: 16000000,
        device: "/dev/ACM0",
        baud_rate: "115200",
        programmer: "stk500",
        mcu: "atmega1280"
      },

      "uno" => {
        variant: "standard",
        clock_speed: 16000000,
        device: "/dev/USB0",
        baud_rate: "57600",
        programmer: "arduino",
        mcu: "atmega328p"

      },
      "mini" => {
        variant: "standard",
        clock_speed: 16000000,
        device: "/dev/USB0",
        baud_rate: "57600",
        programmer: "arduino",
        mcu: "atmega328p"
      },
      "mini3v" => {
        variant: "standard",
        clock_speed: 8000000,
        device: "/dev/USB0",
        baud_rate: "57600",
        programmer: "arduino",
        mcu: "atmega328p"
      }
    }


    def initialize probe_options = {}
      @probe_options = probe_options
      @options = {}
    end

    def probe
      probe_device
      probe_variant
    end

    def probe_variant
      if @options[:device] && @options[:device] =~ /ACM[0-9]/
        @options[:variant] = "mega"
      else
        @options[:variant] = "standard"
      end
    end

    def probe_device
      @options[:device] = DEVICES[0]
      DEVICES.each do |d|
        if File.exist?(d)
          @options[:device] = d
          break
        end
      end
    end
  end
end
