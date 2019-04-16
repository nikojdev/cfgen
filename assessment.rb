#!/usr/bin/ruby
#Deployment script - Assesment
#TODO validations & handling of inputs
#TODO validate the cf template with aws cli

require './lib/cfgen'
require 'optparse'
require 'rubygems'
require 'json'
require 'pp'

#load config File
config_json = File.read('./conf/config.json')
config = JSON.parse(config_json)

#parse command line arguments
file = __FILE__
ARGV.options do |opts|
  opts.on("-vpcname", "--vpcname=val", String)   { |val| config["vpc_name"] = val }
  opts.on("-region", "--region=val", String)   { |val| config["vpc_region"] = val }
  opts.on("-vpcip", "--vpcip=val", String)   { |val| config["vpc_ip"] = val }
  opts.on("-subnet_ip", "--cidrsubnet=val", String)   { |val| config["subnet_ip"] = val }
  opts.on("-sship", "--sship=val", String)   { |val| config["ssh_ip"] = val }
  opts.on("-ec2type", "--ec2type=val", String)   { |val| config["instance_type"] = val }
  opts.on("--azlist=[x,y,z]", Array)     { |val| config["az_list"] = val }
  opts.on_tail("-h", "--help")         { exec "grep ^#/<'#{file}'|cut -c4-" }
  opts.parse!
end

# generate template
template = Cfgen::Template.new(config)
template.prepare_template
cf_template = template.get_template

#output the template
puts JSON.pretty_generate(cf_template)
#template.testall
