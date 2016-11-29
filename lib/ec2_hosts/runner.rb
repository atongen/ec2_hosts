module Ec2Hosts
  class Runner

    def initialize(args)
      @options = Options.new(args).options
    end

    def run!
      if @options[:vpc] && @options[:clear]
        raise ArgumentError.new("Cannot specify 'clear' and 'vpc' at the same time.")
      end

      updater = Updater.new(@options)

      if @options[:clear]
        updater.clear
      else
        if @options[:vpc].nil?
          raise ArgumentError.new("No ec2 vpc specified.")
        end

        if @options[:delete]
          new_hosts_list = []
        else
          hosts = Hosts.new(@options)
          new_hosts_list = hosts.to_a
        end

        updater.update(new_hosts_list)
      end
    end
  end
end
