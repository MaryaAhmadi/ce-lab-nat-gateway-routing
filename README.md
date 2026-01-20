# Lab M3.02 - Configure NAT Gateway and Routing

**Repository:** [https://github.com/cloud-engineering-bootcamp/ce-lab-nat-gateway-routing](https://github.com/cloud-engineering-bootcamp/ce-lab-nat-gateway-routing)

**Activity Type:** Individual  
**Estimated Time:** 45-60 minutes

## Learning Objectives

- [ ] Understand the purpose and function of NAT Gateway
- [ ] Allocate and manage Elastic IP addresses
- [ ] Deploy NAT Gateway in public subnet
- [ ] Configure private subnet routing through NAT
- [ ] Test outbound internet connectivity from private instances
- [ ] Verify inbound traffic is properly blocked

## Your Task

Enable outbound internet access for private subnet resources while maintaining security:
1. Allocate Elastic IP for NAT Gateway
2. Deploy NAT Gateway in public subnet
3. Update private route table to use NAT Gateway
4. Launch test EC2 instance in private subnet
5. Verify outbound access works, inbound is blocked

**Success Criteria:** Private instance can download from internet but cannot be reached from internet.

## Quick Start

```bash
# 1. Allocate Elastic IP
aws ec2 allocate-address --domain vpc

# 2. Create NAT Gateway (in public subnet)
aws ec2 create-nat-gateway \
  --subnet-id subnet-public-1a \
  --allocation-id eipalloc-xxxxx

# 3. Wait for NAT Gateway to be available
aws ec2 wait nat-gateway-available --nat-gateway-ids nat-xxxxx

# 4. Update private route table
aws ec2 create-route \
  --route-table-id rtb-private \
  --destination-cidr-block 0.0.0.0/0 \
  --nat-gateway-id nat-xxxxx

# 5. Test from private instance
curl http://checkip.amazonaws.com
```

## 📤 What to Submit

**Submission Type:** GitHub Repository

Create a **public** GitHub repository named `ce-lab-nat-gateway` containing:

### Required Files

**1. README.md**
- NAT Gateway architecture explanation
- Why NAT is needed for private subnets
- Step-by-step implementation process
- Testing methodology and results
- Security considerations

**2. Configuration Files** (`config/` folder)
- `elastic-ip-details.txt` - EIP allocation info
- `nat-gateway-config.txt` - NAT Gateway details
- `route-table-before.txt` - Private RT before NAT
- `route-table-after.txt` - Private RT after NAT
- `test-commands.sh` - Commands used for testing

**3. Screenshots** (`screenshots/` folder)
- Elastic IP allocation
- NAT Gateway in "Available" state
- Private route table with NAT route
- Test EC2 instance details
- Successful outbound test (curl result)
- Failed inbound test (timeout/blocked)

**4. Cost Analysis** (`cost-analysis.md`)
- NAT Gateway monthly cost estimation
- Data transfer cost projection
- Alternative approaches (NAT Instance, VPC Endpoints)
- Cost optimization recommendations

### Repository Structure
```
ce-lab-nat-gateway/
├── README.md
├── cost-analysis.md
├── config/
│   ├── elastic-ip-details.txt
│   ├── nat-gateway-config.txt
│   ├── route-table-before.txt
│   ├── route-table-after.txt
│   └── test-commands.sh
└── screenshots/
    ├── 01-elastic-ip-allocation.png
    ├── 02-nat-gateway-available.png
    ├── 03-private-route-updated.png
    ├── 04-test-instance-private.png
    ├── 05-outbound-success.png
    └── 06-inbound-blocked.png
```

## Grading: 100 points

- NAT Gateway properly configured: 30pts
- Route table correctly updated: 25pts
- Testing demonstrates correct behavior: 25pts
- Documentation and cost analysis: 15pts
- Security validation: 5pts

## Detailed Instructions

### Part 1: Prerequisites (5 min)

**Verify from Lab M3.01:**
- [ ] VPC exists (10.0.0.0/16)
- [ ] Public subnet exists with IGW route
- [ ] Private subnet exists (no internet route)
- [ ] Internet Gateway attached to VPC

### Part 2: Allocate Elastic IP (5 min)

**Why Elastic IP?**
NAT Gateway needs a static public IP that persists across restarts.

**Console:**
1. Go to VPC → Elastic IPs
2. Click "Allocate Elastic IP address"
3. Click "Allocate"
4. Tag with Name: `nat-gateway-eip`

**CLI:**
```bash
# Allocate EIP
EIP_ALLOC=$(aws ec2 allocate-address --domain vpc \
  --tag-specifications 'ResourceType=elastic-ip,Tags=[{Key=Name,Value=nat-gateway-eip}]' \
  --query 'AllocationId' --output text)

echo "EIP Allocation ID: $EIP_ALLOC"

# View details
aws ec2 describe-addresses --allocation-ids $EIP_ALLOC
```

**Save this info:**
```
Allocation ID: eipalloc-xxxxx
Public IP: 3.80.50.100
```

### Part 3: Create NAT Gateway (10 min)

**Important:** Deploy NAT Gateway in PUBLIC subnet (not private)!

**Console:**
1. Go to VPC → NAT Gateways
2. Click "Create NAT Gateway"
3. Name: `bootcamp-nat-gw`
4. Subnet: Select public-subnet-1a
5. Elastic IP: Select your allocated EIP
6. Click "Create NAT Gateway"
7. Wait 2-3 minutes for state: Available

**CLI:**
```bash
# Get public subnet ID (from Lab M3.01)
PUBLIC_SUBNET_1=$(aws ec2 describe-subnets \
  --filters "Name=tag:Name,Values=public-subnet-1a" \
  --query 'Subnets[0].SubnetId' --output text)

# Create NAT Gateway
NAT_GW=$(aws ec2 create-nat-gateway \
  --subnet-id $PUBLIC_SUBNET_1 \
  --allocation-id $EIP_ALLOC \
  --tag-specifications 'ResourceType=natgateway,Tags=[{Key=Name,Value=bootcamp-nat-gw}]' \
  --query 'NatGateway.NatGatewayId' --output text)

echo "NAT Gateway ID: $NAT_GW"

# Wait for available state
aws ec2 wait nat-gateway-available --nat-gateway-ids $NAT_GW
echo "NAT Gateway is now available!"
```

**Verify Status:**
```bash
aws ec2 describe-nat-gateways --nat-gateway-ids $NAT_GW

# Check for:
# - State: available
# - SubnetId: public subnet
# - NatGatewayAddresses: Your EIP
```

### Part 4: Update Private Route Table (10 min)

**Before (Private RT):**
```
Destination      Target
10.0.0.0/16   →  local
```

**After (Private RT):**
```
Destination      Target
10.0.0.0/16   →  local
0.0.0.0/0     →  nat-xxxxxx  ← NEW ROUTE
```

**Console:**
1. Go to VPC → Route Tables
2. Select `private-rt`
3. Routes tab → Edit routes
4. Add route:
   - Destination: `0.0.0.0/0`
   - Target: NAT Gateway (select your NAT Gateway)
5. Save changes

**CLI:**
```bash
# Get private route table ID
PRIVATE_RT=$(aws ec2 describe-route-tables \
  --filters "Name=tag:Name,Values=private-rt" \
  --query 'RouteTables[0].RouteTableId' --output text)

# Add NAT Gateway route
aws ec2 create-route \
  --route-table-id $PRIVATE_RT \
  --destination-cidr-block 0.0.0.0/0 \
  --nat-gateway-id $NAT_GW

echo "Route added to private route table"

# Verify
aws ec2 describe-route-tables --route-table-ids $PRIVATE_RT
```

### Part 5: Launch Test EC2 Instance (15 min)

**Create Security Group for Test Instance:**
```bash
# Create security group in private subnet
TEST_SG=$(aws ec2 create-security-group \
  --group-name private-test-sg \
  --description "Security group for NAT Gateway testing" \
  --vpc-id $VPC_ID \
  --query 'GroupId' --output text)

# Allow SSH from your IP (for initial access via bastion)
aws ec2 authorize-security-group-ingress \
  --group-id $TEST_SG \
  --protocol tcp --port 22 --cidr 10.0.0.0/16

# Allow all outbound (default)
```

**Launch EC2 Instance:**
```bash
# Get private subnet ID
PRIVATE_SUBNET_1=$(aws ec2 describe-subnets \
  --filters "Name=tag:Name,Values=private-subnet-1a" \
  --query 'Subnets[0].SubnetId' --output text)

# Launch instance (Amazon Linux 2)
aws ec2 run-instances \
  --image-id ami-0c55b159cbfafe1f0 \
  --instance-type t2.micro \
  --key-name your-key-pair \
  --security-group-ids $TEST_SG \
  --subnet-id $PRIVATE_SUBNET_1 \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=nat-test-instance}]'
```

**Note:** To SSH into this private instance, you'll need:
- A bastion host in public subnet, OR
- AWS Systems Manager Session Manager

### Part 6: Test Connectivity (10 min)

**Connect to Instance:**
```bash
# Option 1: Via Bastion Host
ssh -i keypair.pem ec2-user@bastion-public-ip
ssh ec2-user@10.0.11.10  # Private instance

# Option 2: Via Session Manager (no bastion needed)
aws ssm start-session --target i-xxxxx
```

**Test Outbound Access:**
```bash
# Test 1: Check public IP (should be NAT Gateway's IP)
curl http://checkip.amazonaws.com
# Expected: 3.80.50.100 (your NAT Gateway's EIP)

# Test 2: Download file from internet
curl https://www.google.com
# Expected: Success (HTML response)

# Test 3: Update packages
sudo yum update -y
# Expected: Success (downloads updates)

# Test 4: Ping external host
ping -c 4 8.8.8.8
# Expected: Success
```

**Test Inbound Blocking:**
```bash
# From your laptop (NOT from bastion)
ssh ec2-user@3.80.50.100  # NAT Gateway's public IP
# Expected: Connection timeout (should not work!)

# Try reaching private instance public IP (if it had one)
curl http://PRIVATE_INSTANCE_PUBLIC_IP
# Expected: Timeout (private instance has no public IP)
```

**Expected Results:**
- ✅ Outbound traffic works (can reach internet)
- ✅ Public IP seen by internet is NAT Gateway's EIP
- ✅ Instance can download updates
- ❌ Inbound traffic from internet is blocked
- ❌ Cannot SSH directly to NAT Gateway IP

### Part 7: Verify Architecture (5 min)

**VPC Resource Map:**
1. Go to VPC Dashboard
2. Click on your VPC
3. View "Resource map"
4. Should show:
   - Public subnet with NAT Gateway
   - Private subnet with EC2 instance
   - Routes connecting them

**Traffic Flow Visualization:**
```
Private EC2 (10.0.11.10)
   ↓
Private Route Table (0.0.0.0/0 → nat-xxxxx)
   ↓
NAT Gateway (10.0.1.5 in public subnet)
   ↓
Public Route Table (0.0.0.0/0 → igw-xxxxx)
   ↓
Internet Gateway
   ↓
Internet (sees traffic from 3.80.50.100)
```

## Cost Analysis

**Monthly Costs (us-east-1):**
```
NAT Gateway:
- Hourly charge: $0.045/hour × 730 hours = $32.85/month
- Data processing: $0.045/GB

Example scenarios:
- 100GB data transfer: $32.85 + $4.50 = $37.35/month
- 500GB data transfer: $32.85 + $22.50 = $55.35/month
- 1TB data transfer: $32.85 + $45 = $77.85/month

Elastic IP (while attached): Free
```

**Cost Optimization Ideas:**
1. **Use VPC Endpoints for AWS Services**
   - S3/DynamoDB: Free gateway endpoints
   - Saves NAT Gateway data processing fees

2. **Use NAT Instance for Dev/Test**
   - t3.nano: ~$3.50/month
   - Savings: ~$29/month
   - Trade-off: Manual management required

3. **Schedule Workloads**
   - Stop NAT Gateway when not needed
   - Savings: $1.08/hour stopped

## Reflection Questions

Answer in your README:

1. **Why is NAT Gateway deployed in public subnet, not private?**

2. **What happens if NAT Gateway fails?**

3. **How much would it cost to run NAT Gateway for a year with 200GB/month data?**

4. **Why can't you SSH directly to the NAT Gateway's public IP?**

5. **What are the security benefits of using NAT Gateway vs giving instances public IPs?**

## Bonus Challenges

**+5 points each:**
- [ ] Deploy NAT Gateway in second AZ for high availability
- [ ] Create VPC Endpoint for S3 and test cost savings
- [ ] Compare NAT Gateway vs NAT Instance performance
- [ ] Set up CloudWatch alarms for NAT Gateway bandwidth

## Troubleshooting

**Issue: Private instance can't reach internet**
```bash
# Checklist:
- [ ] NAT Gateway state is "Available"
- [ ] NAT Gateway is in PUBLIC subnet
- [ ] Public subnet has route to IGW (0.0.0.0/0 → igw)
- [ ] Private route table has route to NAT (0.0.0.0/0 → nat)
- [ ] Security group allows outbound traffic
- [ ] NACL allows outbound traffic
```

**Issue: High costs**
```bash
# Investigation:
- Check VPC Flow Logs for high traffic volumes
- Look for applications making excessive API calls
- Consider VPC Endpoints for S3/DynamoDB
- Review data transfer patterns
```

**Issue: NAT Gateway shows "Failed" state**
```bash
# Possible causes:
- Insufficient capacity in AZ
- EIP not properly attached
- Subnet configuration issue

# Solution:
- Delete failed NAT Gateway
- Allocate new EIP
- Create new NAT Gateway
```

## Resources

- [NAT Gateway Documentation](https://docs.aws.amazon.com/vpc/latest/userguide/vpc-nat-gateway.html)
- [NAT Gateway Pricing](https://aws.amazon.com/vpc/pricing/)
- [VPC Endpoints](https://docs.aws.amazon.com/vpc/latest/userguide/vpc-endpoints.html)
- [High Availability NAT](https://docs.aws.amazon.com/vpc/latest/userguide/vpc-nat-gateway.html#nat-gateway-basics)

---

**Excellent work on enabling secure outbound internet access!** 🔒
