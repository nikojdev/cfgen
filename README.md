# Assessment Project

This is project was created for assessment purpose only.

Goal of the project is to create the deployment script using Ruby to generate a valid cloudformation template in json.

## Requirements of the assessment

Generated json template should:

- generate a valid cloudformation template
- A VPC with three subnets. The VPC should have an IP-range of /16, the subnets /20
- A security group for the VPC.
- An S3 bucket with a randomly generated name and an ACL that denies access to anyone except for the owner.
- Inside the VPC should be an EC2-instance with these specifications:
- The region should be eu-west-1
- The ami should be the latest Amazon Linux AMI available
- The instance type should be of the smallest general purpose type
- The security group should only allow SSH access from 35.158.238.101/32

## The Solution
Note: I'm not a Ruby developer & I haven't done projects with Ruby before

The goal was to create reusable module which can be extended & use the configuration dynamically with configuration or with user input to not make it less rigid. For the basic projects structure I have utilized bundler to generate the gem project skeleton. Under `lib/cfgen/cfgen.rb` which contains the class Template. Each different component of the template is generated separately (vpc, ec2, parameters, subnets etc.) so that it could be used in that way if ever required, we could create seperate templates based on individual components. Template class handles loading of json templates, manipulation of json templates based on configurations passed to it & creation (merging the templates) of cloudformation template. Based on requirements, there is script `assessment.rb` which creates instances of the Template class with user configuration settings and outputs the generated cloudformation template.

Assumptions:
- script will be used for different purposes for different scenarios, therefore we utilize configuration file
- assuming that login into ec2 instance is not required, therefore no keys are mentioned in generated ec2 part of template
- no custom ACL is generated for s3 bucket since default ACL which is created on creation of any new s3 bucket already fits the requirements
- for latest ami we are using AWS::SSM::Parameter::Value

Further improvements:
- utilize the aws cli to validate the template outputs
- validate the inputs
- ssh script
- output the template as file and upload to s3 bucket_new
- write more test cases
- integrate with travisci/circleci for testing

## How to use the deployment script
with Default settings:
- ruby assessment.rb

Custom settings with config file:
- edit: `conf/configuration.json`
- run: ruby assessment.rb

Custom settings command line options
-  example run: ruby assessment.rb -vpcname "yourVPCname"

## Testing

- bundle exec rspec spec

## How to modify

Code: `lib`
Configuration: `conf/config.json`
Templates: `templates/json`
