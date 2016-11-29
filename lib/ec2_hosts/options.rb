require 'optparse'

module Ec2Hosts
  class Options

    attr_reader :options

    def initialize(args)
      @options = {
        vpc: nil,
        template: nil
        public: nil,
        exclude_public: false,
        file: '/etc/hosts',
        backup: nil,
        dry_run: false,
        delete: false,
        clear: false
      }
      parser.parse!(args)
    end

    private

    def parser
      @parser ||= begin
        OptionParser.new do |opts|
          opts.banner = "Usage: $ ec2_hosts [options]"
          opts.on('-v', '--vpc VPC_NAME', "Name of VPC to use. Defaults to nil.") do |opt|
            @options[:vpc] = opt
          end
          opts.on('-t', '--template TEMPLATE', "Template string to use to convert instance tags to hostname. Defaults to nil.") do |opt|
            @options[:template] = opt
          end
          opts.on('-p', '--public PUBLIC', "Pattern to match for public/bastion hosts. Use public IP for these. Defaults to nil") do |opt|
            @options[:public] = opt
          end
          opts.on('--[no-]exclude-public', "Exclude public hosts from list when updating hosts file. Allows them to be managed manually. Defaults to false") do |opt|
            @options[:exclude_public] = opt
          end
          opts.on('-f', '--file FILE', "Hosts file to update. Defaults to /etc/hosts") do |opt|
            @options[:file] = opt
          end
          opts.on('-b', '--backup BACKUP', "Path to backup original hosts file to. Defaults to FILE with '.bak' extension appended.") do |opt|
            @options[:file] = opt
          end
          opts.on('--[no-]dry-run', "Dry run, do not modify hosts file. Defaults to false") do |opt|
            @options[:dry_run] = opt
          end
          opts.on('--[no-]delete', "Delete the VPC from hosts file. Defaults to false") do |opt|
            @options[:delete] = opt
          end
          opts.on('--[no-]clear', "Clear all ec2 host entries from hosts file. Defaults to false") do |opt|
            @options[:clear] = opt
          end
          opts.on_tail("--help", "Show this message") do
            puts opts
            exit
          end
          opts.on_tail("--version", "Show version") do
            puts ::Ec2Hosts::VERSION
            exit
          end
        end
      end
    end
  end
end