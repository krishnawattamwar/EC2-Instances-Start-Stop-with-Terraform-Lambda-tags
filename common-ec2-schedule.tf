resource "aws_lambda_function" "instance_scheduler" {
  filename         = "common-ec2-schedule.zip" # Ensure you have the ZIP file containing your Lambda function code
  function_name   = "ec2-instance-nonprod-start-stop" #Lambda function name
  role            = aws_iam_role.lambda_role.arn
  handler         = "lambda_function.lambda_handler"
  runtime         = "python3.8"
}

resource "aws_iam_role" "lambda_role" {
  name = "ec2-instance-start-stop-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_policy" "lambda_policy" {
  name        = "ec2-instance-start-stop-lambda-policy"
  description = "Policy for EC2 scheduling Lambda function"
  
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": [
                "ec2:DescribeInstances",
                "ec2:DescribeTags",
                "ec2:Start*",
                "ec2:Stop*"
            ],
            "Resource": "*"
        },
        {
            "Sid": "VisualEditor1",
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogStream",
                "logs:CreateLogGroup",
                "logs:PutLogEvents"
            ],
            "Resource": "arn:aws:logs:*:*:*"
        }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_policy_attachment" {
  policy_arn = aws_iam_policy.lambda_policy.arn
  role       = aws_iam_role.lambda_role.name
}

resource "aws_cloudwatch_event_rule" "schedule_rule" {
  name        = "ec2-instance-nonprod-start-stop"
  description = "Schedule rule to trigger Lambda at specific times"

  schedule_expression = "cron(30 3,15 ? * MON-FRI *)" # Adjust the schedule expression for 9 AM and 9 PM IST #GMT timze zone
}

resource "aws_cloudwatch_event_target" "schedule_target" {
  rule      = aws_cloudwatch_event_rule.schedule_rule.name
  target_id = "ec2-instance-nonprod-start-stop"

  arn = aws_lambda_function.instance_scheduler.arn
}