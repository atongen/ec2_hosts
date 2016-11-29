require 'ec2_hosts/version'
require 'ec2_hosts/options'
require 'ec2_hosts/hosts'
require 'ec2_hosts/updater'
require 'ec2_hosts/runner'

module Ec2Hosts
  class HostError < StandardError; end
  class UpdaterError < StandardError; end
end
