# NBA Game Day Notifications System

A serverless notification system built on AWS that delivers real-time NBA game updates via SMS and email. This project uses Terraform for infrastructure provisioning and Python for the core notification logic.

## System Architecture

```
EventBridge (Trigger) → Lambda (Processing) → SNS (Notification Delivery)
```
![diagram](https://github.com/user-attachments/assets/1e54f73a-27d3-4838-8bab-e3137ec4987d)

The system follows a simple serverless workflow:
1. EventBridge triggers the Lambda function on a scheduled basis
2. Lambda fetches and processes game data from the Sports API
3. Processed updates are published to SNS topic
4. SNS delivers notifications to subscribed endpoints (SMS/Email)

## Prerequisites

- AWS Account with appropriate permissions
- Terraform installed (v1.0.0+)
- Python 3.9+
- [SportsData.io](https://sportsdata.io/) API key
- AWS CLI configured with your credentials

## Project Structure

```
nba-notifications/
├── terraform/
│   ├── main.tf              # Main Terraform configuration
│   ├── variables.tf         # Variable definitions
│   ├── outputs.tf           # Output definitions
│   └── terraform.tfvars     # Variable values (git-ignored)
├── src/
│   └── gd_notifications.py  # Lambda function code
├── .gitignore
└── README.md
```

## Quick Start

1. **Clone the Repository**
```bash
git clone https://github.com/your-username/nba-notifications.git
cd nba-notifications
```

2. **Configure Environment Variables**
```bash
# Copy example vars file
cp terraform/terraform.tfvars.example terraform/terraform.tfvars

# Edit with your values
vim terraform/terraform.tfvars
```

Required variables in `terraform.tfvars`:
```hcl
aws_region   = "us-east-1"
nba_api_key  = "your-api-key"
project_name = "nba-notifications"
```

3. **Deploy Infrastructure**
```bash
cd terraform
terraform init
terraform plan
terraform apply
```

4. **Add SNS Subscriptions**
- Navigate to the SNS topic in AWS Console
- Add email/SMS subscriptions manually
- Confirm subscriptions via email/SMS

5. **Test the System**
```bash
# Trigger Lambda function manually
aws lambda invoke \
  --function-name nba-notifications-function \
  --payload '{}' \
  response.json
```

## Configuration Details

### Terraform Resources Created

- Lambda Function with Python runtime
- EventBridge rule with cron schedule
- SNS topic for notifications
- IAM roles and policies
- CloudWatch log group

### Lambda Environment Variables

| Variable | Description |
|----------|-------------|
| NBA_API_KEY | Your SportsData.io API key |
| SNS_TOPIC_ARN | ARN of the SNS topic |

### EventBridge Schedule

Default schedule is hourly. Modify the cron expression in `main.tf`:
```hcl
schedule_expression = "rate(1 hour)"
```

## Development

### Local Testing

1. Set up Python virtual environment:
```bash
python -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

2. Create test event:
```bash
# Create test event file
echo '{}' > test/event.json
```

3. Run local tests:
```bash
python -m pytest
```

### Modifying Lambda Code

1. Update `src/gd_notifications.py`
2. Zip the updated code:
```bash
cd src
zip ../terraform/lambda_function.zip gd_notifications.py
```
3. Apply Terraform changes:
```bash
cd ../terraform
terraform apply
```

## Maintenance

### Updating Dependencies

1. Update `requirements.txt`
2. Rebuild Lambda deployment package
3. Apply Terraform changes

### Monitoring

- CloudWatch Logs: `/aws/lambda/nba-notifications-function`
- SNS delivery status in CloudWatch metrics
- Lambda execution metrics

## Security

- Least privilege IAM policies
- Environment variables for sensitive values
- API keys stored securely in Lambda
- SNS topic policy restricts publishing

## Costs

This serverless architecture incurs minimal costs:
- Lambda: Pay per execution
- SNS: Pay per message
- EventBridge: Pay per event
- CloudWatch: Logs storage

## Troubleshooting

Common issues and solutions:

1. **Lambda Timeouts**
   - Check Lambda timeout setting in Terraform
   - Review API response times
   - Consider increasing timeout value

2. **SNS Delivery Failures**
   - Verify subscription confirmation
   - Check phone number format
   - Review CloudWatch logs

3. **API Rate Limiting**
   - Implement backoff strategy
   - Review API quota limits
   - Contact API provider if needed

## Future Enhancements

1. Add support for:
   - NFL scores
   - MLB scores
   - NBA player stats

2. Implement:
   - DynamoDB for user preferences
   - Web UI for subscription management
   - Custom notification templates

## Contributing

1. Fork the repository
2. Create feature branch
3. Commit changes
4. Push to branch
5. Create Pull Request

## License

MIT License - see LICENSE file for details

---
For questions or support, please open an issue in the GitHub repository.
