require 'json'

RSpec.describe Cfgen do
  it "has a version number" do
    expect(Cfgen::VERSION).not_to be nil
  end

  it "change the cidrBlock in template" do
    vpc_json = File.read('./templates/json/vpc.json')
    vpc = JSON.parse(vpc_json)
    
    template = Cfgen::Template.new("test")
    output = template.prepare_vpc(vpc, "testVPC", "192.168.0.1/16")
    expect(output['Resources']["testVPC"]["Properties"]["CidrBlock"]).to eq("192.168.0.1/16")
  end
end
