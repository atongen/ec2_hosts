module Ec2Hosts
  class Hosts

    attr_reader :ec2,
                :options

    def initialize(options = {})
      # Creds must be present in environment
      @ec2 = AWS::EC2.new
      @options = options
      @processed_template = process_template
    end

    def vpc
      vpcs = ec2.vpcs.filter("tag:Name", options[:vpc]).map {|v|v}

      if vpcs.length > 1
        raise ArgumentError.new("Multiple VPCs with name '#{options[:vpc]}' found.")
      elsif vpcs.length == 0
        raise ArgumentError.new("VPC '#{options[:vpc]}' not found.")
      end

      vpcs.first
    end

    def instances
      vpc.instances.filter("instance-state-name", "running")
    end

    def to_a
      raw = instances.inject({}) do |memo, inst|
        hostname = nil
        if @processed_template
          hostname = parse_hostname_template(inst.tags.map.to_a)
        end
        if hostname.nil?
          hostname = inst.private_dns_name.split('.').first
        end
        memo[hostname] = inst
        memo
      end.sort.to_h

      list = []

      raw.each do |hostname, inst|
        begin
          if options[:public].to_s.strip != "" && hostname.downcase.include?(options[:public])
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

  def process_template
    return nil if options[:template].nil?

    options[:template].split(/({\w+})/).select { |s| s != "" }.map do |snip|
      if m = snip.match(/\A{(\w+)}\Z/)
        ->(tags) { tags[m[1]] }
      else
        snip
      end
    end
  end

  def parse_hostname_template(tags)
    result = @processed_template.map do |snip|
      if snip.is_a?(Proc)
        snip.call(tags)
      else
        snip
      end
    end
    if result.any? { |r| r.nil? }
      nil
    else
      result.join
    end
  end
end
