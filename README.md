Readme
==

This is simple build that uses Jenkins pipeline with terraform, shell script on AWS platform.

Steps in Jenkins:
- Say hello to Jenkins
- TEST: validate packer
-- runs packer validate
- BUILD: build AMI with packer
-- aws credentials are in Jenkins app
-- runs setup.sh script from directory 'scripts' in the same git repo
-- ssh key for user created via setup.sh is from directory 'secrets' in the same git repo
-- the result is ami with timestamp in name, for later use with terraform
- BUILD: deploy ec2 with terraform