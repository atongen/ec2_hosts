module Ec2Hosts
  class Hosts

    attr_reader :ec2,
                :options

    def initialize(options = {})
      # Creds must be present in environment
      @ec2 = AWS::EC2.new
      @options = options
      if @options[:tags]
        @processed_tags = process_tags(@options[:tags])
      elsif @options[:template]
        @processed_template = process_template(@options[:template])
      end
    end

    def vpc
      return @vpc if instance_variable_defined?(:@vpc)

      vpcs = ec2.vpcs.filter("tag:Name", options[:vpc]).map {|v|v}

      if vpcs.length > 1
        raise ArgumentError.new("Multiple VPCs with name '#{options[:vpc]}' found.")
      elsif vpcs.length == 0
        raise ArgumentError.new("VPC '#{options[:vpc]}' not found.")
      end

      @vpc = vpcs.first
    end

    def instances
      return @instances if instance_variable_defined?(:@instances)

      if options[:only_running]
        @instances = vpc.instances.filter("instance-state-name", "running")
      else
        @instances = vpc.instances
      end
    end

    def to_a
      raw = instances.inject({}) do |memo, inst|
        hostname = nil
        if @processed_tags
          hostname = parse_tags_hostname(@processed_tags, inst.tags.map.to_a.to_h)
        elsif @processed_template
          hostname = parse_template_hostname(@processed_template, inst.tags.map.to_a.to_h)
        end

        if hostname == "" && !options[:ignore_missing]
          hostname = inst.private_dns_name.split('.').first
        end

        if hostname != ""
          memo[hostname] = inst
        end

        memo
      end.sort.to_h

      list = []

      raw.each do |hostname, inst|
        begin
          if !options[:public].nil? && hostname.downcase.include?(options[:public])
            if !options[:exclude_public]
              # get public ip address
              if ip = inst.public_ip_address
                list << "#{ip} #{hostname}"
                raise HostError.new
              end
            end
          else
            # get private ip address
            if ip = inst.private_ip_address
              list << "#{ip} #{hostname}"
              raise HostError.new
            end
          end
        rescue HostError; end
      end

      list
    end

  private

    def process_template(template)
      template.split(/({\w+})/).select { |s| s != "" }.map do |snip|
        if m = snip.match(/\A{(\w+)}\Z/)
          ->(tags) { tags[m[1]] }
        else
          snip
        end
      end
    end

    def parse_template_hostname(template, instance_tags)
      result = template.map do |snip|
        if snip.is_a?(Proc)
          snip.call(instance_tags)
        else
          snip
        end
      end
      if result.any? { |r| r.nil? }
        ""
      else
        result.join.gsub('_', '-')
      end
    end

    def process_tags(tags)
      tags.split(",").select { |s| s != "" }
    end

    def parse_tags_hostname(tags, instance_tags)
      tags.map do |tag|
        instance_tags[tag]
      end.compact.join("-").gsub('_', '-')
    end
  end
end
