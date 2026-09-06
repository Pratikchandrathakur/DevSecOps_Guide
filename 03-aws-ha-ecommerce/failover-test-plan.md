# Failover and Resilience Test Plan

## Test 1: App Node Failure
- Stop one EC2 instance
- Expected:
  - TG marks unhealthy quickly
  - ASG terminates and replaces instance
  - No visible outage via ALB

## Test 2: AZ Disturbance Simulation
- Restrict one AZ app subnet path (controlled test)
- Expected:
  - Remaining AZ continues serving traffic

## Test 3: RDS Manual Failover
- Trigger failover from RDS console
- Expected:
  - Endpoint flips to standby within ~60-120 seconds
  - App reconnects without config changes

## Evidence Collection
- ALB health logs/screenshots
- ASG activity history
- RDS event logs
- Customer-impact window duration
