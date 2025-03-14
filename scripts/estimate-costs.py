#!/usr/bin/env python3

import argparse
import json
import sys
from datetime import datetime, timedelta

# Default cost estimates based on US East (N. Virginia) region
DEFAULT_COSTS = {
    "fargate": {
        "cpu": 0.04048,  # per vCPU-hour
        "memory": 0.004445  # per GB-hour
    },
    "alb": {
        "hourly": 0.0225,  # per hour
        "lcu": 0.008  # per LCU-hour
    },
    "ecr": {
        "storage": 0.10  # per GB-month
    },
    "cloudwatch": {
        "logs": 0.50,  # per GB
        "metrics": 0.30,  # per metric per month
        "dashboard": 3.00  # per dashboard per month
    },
    "data_transfer": {
        "out": 0.09  # per GB
    }
}

def calculate_fargate_cost(vcpu, memory_gb, tasks, hours_per_day, days_per_month):
    """Calculate the monthly cost for ECS Fargate tasks."""
    hours_per_month = hours_per_day * days_per_month
    cpu_cost = DEFAULT_COSTS["fargate"]["cpu"] * vcpu * tasks * hours_per_month
    memory_cost = DEFAULT_COSTS["fargate"]["memory"] * memory_gb * tasks * hours_per_month
    return cpu_cost + memory_cost

def calculate_alb_cost(hours_per_day, days_per_month, requests_per_day=10000):
    """Calculate the monthly cost for Application Load Balancer."""
    hours_per_month = hours_per_day * days_per_month
    hourly_cost = DEFAULT_COSTS["alb"]["hourly"] * hours_per_month
    
    # Estimate LCU usage based on requests
    # 1 LCU = 1 request per second sustained for an hour
    requests_per_second = requests_per_day / (hours_per_day * 3600)
    lcu_cost = DEFAULT_COSTS["alb"]["lcu"] * requests_per_second * hours_per_month
    
    return hourly_cost + lcu_cost

def calculate_ecr_cost(repositories, storage_gb):
    """Calculate the monthly cost for ECR."""
    return DEFAULT_COSTS["ecr"]["storage"] * storage_gb

def calculate_cloudwatch_cost(log_gb, metrics, dashboards):
    """Calculate the monthly cost for CloudWatch."""
    logs_cost = DEFAULT_COSTS["cloudwatch"]["logs"] * log_gb
    metrics_cost = DEFAULT_COSTS["cloudwatch"]["metrics"] * metrics
    dashboard_cost = DEFAULT_COSTS["cloudwatch"]["dashboard"] * dashboards
    return logs_cost + metrics_cost + dashboard_cost

def calculate_data_transfer_cost(gb_out):
    """Calculate the monthly cost for data transfer."""
    return DEFAULT_COSTS["data_transfer"]["out"] * gb_out

def format_cost(cost):
    """Format cost with 2 decimal places and dollar sign."""
    return f"${cost:.2f}"

def main():
    parser = argparse.ArgumentParser(description='Estimate AWS costs for microservices deployment')
    
    # Fargate parameters
    parser.add_argument('--vcpu', type=float, default=0.25, help='vCPU per task (default: 0.25)')
    parser.add_argument('--memory', type=float, default=0.5, help='Memory in GB per task (default: 0.5)')
    parser.add_argument('--tasks', type=int, default=2, help='Number of tasks (default: 2)')
    
    # Usage parameters
    parser.add_argument('--hours', type=int, default=24, help='Hours per day (default: 24)')
    parser.add_argument('--days', type=int, default=30, help='Days per month (default: 30)')
    parser.add_argument('--requests', type=int, default=10000, help='Requests per day (default: 10000)')
    
    # Storage parameters
    parser.add_argument('--repositories', type=int, default=2, help='Number of ECR repositories (default: 2)')
    parser.add_argument('--storage', type=float, default=1.0, help='ECR storage in GB (default: 1.0)')
    
    # CloudWatch parameters
    parser.add_argument('--logs', type=float, default=1.0, help='CloudWatch logs in GB per month (default: 1.0)')
    parser.add_argument('--metrics', type=int, default=10, help='Number of CloudWatch metrics (default: 10)')
    parser.add_argument('--dashboards', type=int, default=1, help='Number of CloudWatch dashboards (default: 1)')
    
    # Data transfer parameters
    parser.add_argument('--data-out', type=float, default=10.0, help='Data transfer out in GB per month (default: 10.0)')
    
    # Output format
    parser.add_argument('--json', action='store_true', help='Output in JSON format')
    
    args = parser.parse_args()
    
    # Calculate costs
    fargate_cost = calculate_fargate_cost(args.vcpu, args.memory, args.tasks, args.hours, args.days)
    alb_cost = calculate_alb_cost(args.hours, args.days, args.requests)
    ecr_cost = calculate_ecr_cost(args.repositories, args.storage)
    cloudwatch_cost = calculate_cloudwatch_cost(args.logs, args.metrics, args.dashboards)
    data_transfer_cost = calculate_data_transfer_cost(args.data_out)
    
    total_cost = fargate_cost + alb_cost + ecr_cost + cloudwatch_cost + data_transfer_cost
    
    # Prepare results
    results = {
        "fargate": fargate_cost,
        "alb": alb_cost,
        "ecr": ecr_cost,
        "cloudwatch": cloudwatch_cost,
        "data_transfer": data_transfer_cost,
        "total": total_cost
    }
    
    # Output results
    if args.json:
        print(json.dumps(results, indent=2))
    else:
        print("\nAWS Cost Estimate for Microservices Deployment")
        print("==============================================")
        print(f"ECS Fargate ({args.tasks} tasks, {args.vcpu} vCPU, {args.memory}GB memory): {format_cost(fargate_cost)}")
        print(f"Application Load Balancer: {format_cost(alb_cost)}")
        print(f"ECR ({args.repositories} repositories, {args.storage}GB storage): {format_cost(ecr_cost)}")
        print(f"CloudWatch (logs: {args.logs}GB, metrics: {args.metrics}, dashboards: {args.dashboards}): {format_cost(cloudwatch_cost)}")
        print(f"Data Transfer ({args.data_out}GB out): {format_cost(data_transfer_cost)}")
        print("----------------------------------------------")
        print(f"Total Estimated Monthly Cost: {format_cost(total_cost)}")
        print("\nNote: These estimates are based on US East (N. Virginia) region pricing and may vary based on actual usage.")
        print("For more accurate estimates, use the AWS Pricing Calculator: https://calculator.aws")

if __name__ == "__main__":
    main()