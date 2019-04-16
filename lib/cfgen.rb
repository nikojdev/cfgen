require "./lib/cfgen/version"

module Cfgen
  class Error < StandardError; end

  class Template
    def initialize(config)
      @config = config
    end

    def prepare_template
      load_templates
      prepare_all
      merge_all
    end

    # This method loads all of the json template files and parse it
    def load_templates
      # read json templates
      vpc_json = File.read('./templates/json/vpc.json')
      subnet_json = File.read('./templates/json/subnet.json')
      bucket_json = File.read('./templates/json/s3bucket.json')
      parameters_json = File.read('./templates/json/parameters.json')
      ec2_json = File.read('./templates/json/ec2.json')

      #parse
      @vpc = JSON.parse(vpc_json)
      @subnet = JSON.parse(subnet_json)
      @bucket = JSON.parse(bucket_json)
      @parameters = JSON.parse(parameters_json)
      @ec2 = JSON.parse(ec2_json)
    end

    # This method orchestrates each single template creation and stores as output
    def prepare_all
      @vpc_output = prepare_vpc(@vpc, @config["vpc_name"], @config["cidr_vpc"])
      @subnet_output = prepare_subnet(@subnet, @config["vpc_name"], @config["cidr_subnet"], @config["az_list"])
      @s3bucket_output = prepare_s3(@bucket)
      @ec2_output = prepare_ec2(@ec2, "Subnet1", @config["vpc_name"], "LatestAmiId", @config["ssh_ip"], @config["instance_type"])
    end

    # This method is responsible for merging the templates together
    def merge_all
      @vpc_output["Parameters"] = @parameters["Parameters"]
      @vpc_output["Resources"].merge!(@subnet_output["Resources"]).merge!(@s3bucket_output["Resources"]).merge!(@ec2_output["Resources"])
    end

    # this method gets the generated cloudformation json template
    def get_template
      @vpc_output
    end

    #this method prepares the vpc from template
    def prepare_vpc(vpc, vpc_name, cidr_vpc)
      vpc_new = deep_copy(vpc)
      vpc_old = deep_copy(vpc['Resources']['myVPC'])

      #assign the values accordingly
      vpc_new['Resources'][vpc_name] = vpc_old
      vpc_new['Resources'][vpc_name]["Properties"]["CidrBlock"] = cidr_vpc
      vpc_new['Resources'].delete("myVPC")
      return vpc_new
    end

    #this method prepares the subnets from template
    def prepare_subnet(subnet, vpc_name, cidr_subnet, az_list)
      subnet_new = deep_copy(subnet)
      subnet_old = deep_copy(subnet['Resources']['mySubnet'])
      az_count = 0;

      for x in 0..3
        #assign the values accordingly
        subnet_name = "Subnet#{x+1}"
        subnet_new['Resources'][subnet_name] = deep_copy(subnet_old)
        subnet_new['Resources'].delete("mySubnet")
        subnet_new['Resources'][subnet_name]['Properties']['VpcId']['Ref'] = vpc_name
        subnet_new['Resources'][subnet_name]['Properties']['CidrBlock']['Fn::Select'][0] = x
        subnet_new['Resources'][subnet_name]['Properties']['AvailabilityZone'] = az_list[az_count]
        subnet_new['Resources'][subnet_name]['Properties']['Tags'][0]["Value"] = subnet_name

        #count according to number of az's in region
        az_count = az_count < (az_list.length-1) ? (az_count = az_count + 1) : (az_count = 0)
      end
      return subnet_new
    end

    #this method prepares the s3 from template
    def prepare_s3(bucket)
      bucket_new = deep_copy(bucket)
      bucket_old = deep_copy(bucket['Resources']['EncryptedS3Bucket'])
      bucket_name = "bucket#{rand(1...99999)}-${AWS::StackName}-${AWS::AccountId}"

      #assign the values accordingly
      bucket_new['Resources']["EncryptedS3Bucket"]["Properties"]["BucketName"]["Fn::Sub"] = bucket_name
      bucket_new['Resources'].delete("myVPC")

      return bucket_new
    end

    #this method prepares the ec2 and sg from template
    def prepare_ec2(ec2, subnet, vpc, image_ref, ssh_ip, instance_type)
      ec2_new = deep_copy(ec2)
      #ec2_old = deep_copy(ec2['Resources']['MyEC2Instance'])

      #assign the values accordingly
      ec2_new['Resources']["MyEC2Instance"]["Properties"]["ImageId"]["Ref"] = image_ref
      ec2_new['Resources']["MyEC2Instance"]["Properties"]["InstanceType"] = instance_type
      ec2_new['Resources']["MyEC2Instance"]["Properties"]["SubnetId"]["Ref"] = subnet
      ec2_new['Resources']["InstanceSecurityGroup"]["Properties"]["VpcId"]["Ref"] = vpc
      ec2_new['Resources']["InstanceSecurityGroup"]["Properties"]["SecurityGroupIngress"][0]["CidrIp"] = ssh_ip
      #ec2_new['Resources'].delete("myVPC")

      return ec2_new
    end

    #deep cloning helper method
    def deep_copy(o)
      Marshal.load(Marshal.dump(o))
    end
  end
end
