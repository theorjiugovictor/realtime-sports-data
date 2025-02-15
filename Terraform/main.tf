# Configure AWS Provider
provider "aws" {
  region = var.aws_region
}

# Variables
variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name to be used for resource naming"
  type        = string
  default     = "nba-game-notifications"
}

variable "nba_api_key" {
  description = "API key for NBA data service"
  type        = string
  sensitive   = true
}

# SNS Topic
resource "aws_sns_topic" "game_notifications" {
  name = "${var.project_name}-topic"
}

# SNS Topic Policy
resource "aws_sns_topic_policy" "default" {
  arn = aws_sns_topic.game_notifications.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowLambdaToPublish"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action   = "SNS:Publish"
        Resource = aws_sns_topic.game_notifications.arn
      }
    ]
  })
}

# Lambda IAM Role
resource "aws_iam_role" "lambda_role" {
  name = "${var.project_name}-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

# Lambda Role Policy
resource "aws_iam_role_policy" "lambda_policy" {
  name = "${var.project_name}-lambda-policy"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sns:Publish",
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = [
          aws_sns_topic.game_notifications.arn,
          "arn:aws:logs:*:*:*"
        ]
      }
    ]
  })
}

# Lambda Function
resource "aws_lambda_function" "game_notifications" {
  filename         = "${path.module}/src/lambda_function.zip"
  function_name    = "${var.project_name}-function"
  role            = aws_iam_role.lambda_role.arn
  handler         = "gd_notifications.lambda_handler"
  runtime         = "python3.9"
  timeout         = 30

  environment {
    variables = {
      NBA_API_KEY    = var.nba_api_key
      SNS_TOPIC_ARN  = aws_sns_topic.game_notifications.arn
    }
  }
}

# EventBridge Rule
resource "aws_cloudwatch_event_rule" "schedule" {
  name                = "${var.project_name}-schedule"
  description         = "Schedule for NBA game notifications"
  schedule_expression = "rate(1 hour)"
}

# EventBridge Target
resource "aws_cloudwatch_event_target" "lambda" {
  rule      = aws_cloudwatch_event_rule.schedule.name
  target_id = "SendToLambda"
  arn       = aws_lambda_function.game_notifications.arn
}

# Lambda Permission for EventBridge
resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowEventBridgeInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.game_notifications.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.schedule.arn
}

# Outputs
output "lambda_function_name" {
  value = aws_lambda_function.game_notifications.function_name
}

output "sns_topic_arn" {
  value = aws_sns_topic.game_notifications.arn
}
