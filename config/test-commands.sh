


#!/bin/bash

# Test outbound from private instance
curl http://checkip.amazonaws.com  # Should show NAT Gateway EIP

# Test internet download
curl https://www.google.com

# Update the system
sudo yum update -y

# Test inbound (should not succeed)
ssh -i bootcamp-week2-key.pem ec2-user@<NAT-Gateway-Public-IP>
curl http://<Private-Instance-Public-IP-if-any>
