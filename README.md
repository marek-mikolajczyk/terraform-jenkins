# Readme

This is simple build that uses Jenkins pipeline with terraform, shell script on AWS platform - code is in Git repo.


# Repository structure
 
    ├── jenkins - pipeline definition
    ├── packer - build AWS AMI
    ├── scripts - shell scripts for Packer. Configures user 'automation' on ec2
    ├── secrets - ssh keypair for ec2 for user automation
    └── terraform 
           - builds ec2 webserver with security group (port 8080 from world and 22 from my laptop). 
           - builds S3 bucket and puts there the ansible inventory generated from TF template

# Variables

All variables required to run the code are defined in Jenkins app.
On local laptop I source them from  ~/my_envs.sh

- TV_VAR_my_public_ip - defined outside git repo
- AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY

# Steps in Jenkins pipeline
- Say hello to Jenkins
  - just a 'hello world'
- TEST: validate packer
  - runs packer validate
- BUILD: build AMI with packer
  - aws credentials are in Jenkins app
  - runs setup.sh script from directory 'scripts' in the same git repo
  - ssh key for user created via setup.sh is from directory 'secrets' in the same git repo
  - the result is ami with timestamp in name, for later use with terraform
- BUILD: deploy ec2 with terraform
  - builds ec2 webserver with security group
  - builds s3 for ansible inventory and generates there inventory from TF template

# Problems to solve and ideas
1. Terraform statefile is created locally in Jenkins server. To rebuild AWS infra, this state needs to be in S3.
   Main pipeline could be split into 2 - one for creating S3 TF bucket, second for rebuilding AMIs and infra. 
   The code for S3 TF state could be moved to AWS CLI instead of terraform, but then AWS CLI plugin needs to be controlled (binary version).
   Manual action isn't considered as it's not IaC.

   There might be step in pipeline that converts the TF state from local to remote, but then how to keep Git repo up to date ?
   Maybe converting + pipeline conditionals would work?

2. Splitting the pipeline into smaller pipelines would be easier to manage the code, but then we need to manage the admins actions.
   Then IaC extends to IaC + long documentation so it's not the result I look for.

3. I'm not sure which method of storing the ssh key is the best. 
   For now, it's in Git repo.

# Issues
1. File /tmp/123 content is not shown on webserver. This means pPcker doesn't work correctly (yet it runs without error).
   Maybe /tmp/123 should be created in different path, because there might be some cleaning mechanism ?
   
2. SG has timestamp in name because there was some problem with recreating the resource.
   Maybe it comes that TF state is not in S3