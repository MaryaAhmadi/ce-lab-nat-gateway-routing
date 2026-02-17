

# NAT Gateway Cost Analysis

## 1. NAT Gateway Costs

**Hourly charge (us-east-1):** $0.045/hour  
**Monthly (730 hours):** $0.045 × 730 = $32.85/month  

**Data processing charge:** $0.045 per GB

### Example Scenarios:

| Data Transfer | Cost Calculation | Total Cost |
|---------------|-----------------|------------|
| 100 GB        | $32.85 + (100 × 0.045) | $37.35 |
| 500 GB        | $32.85 + (500 × 0.045) | $55.35 |
| 1 TB          | $32.85 + (1000 × 0.045)| $77.85 |

**Elastic IP**: Free while attached to NAT Gateway  

---

## 2. Alternative Approaches

### NAT Instance
- Use a t3.nano NAT instance: ~$3.50/month  
- Pros: Lower cost  
- Cons: Requires manual patching, monitoring, and scaling  

### VPC Endpoints
- For AWS services like S3 and DynamoDB  
- Free gateway endpoints  
- Saves NAT Gateway data processing fees  

---

## 3. Cost Optimization Recommendations

1. Use VPC endpoints where possible for S3/DynamoDB to reduce NAT traffic.  
2. Schedule NAT Gateway usage only when needed to save costs.  
3. Consider NAT Instance for dev/test environments where high availability is not critical.  

---

## 4. Reflection Questions

- **Why is NAT Gateway deployed in public subnet, not private?**  
  Because private instances need outbound internet access without exposing themselves publicly. NAT Gateway in public subnet routes traffic for them.

- **What happens if NAT Gateway fails?**  
  Private instances lose outbound internet connectivity until a new NAT Gateway is deployed or HA configuration is in place.

- **Cost for 200GB/month data transfer?**  
  $32.85 + (200 × 0.045) = $41.85/month  

- **Why can't you SSH directly to the NAT Gateway's public IP?**  
  NAT Gateway does not accept inbound connections; it only allows outbound traffic from private subnets.

- **Security benefits of NAT Gateway vs giving instances public IPs?**  
  Private instances stay isolated from the internet, reducing attack surface and improving security.
