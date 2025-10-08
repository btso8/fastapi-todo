# SNS for alerts
resource "aws_sns_topic" "alerts" {
  name = "${local.name_prefix}-alerts"
}

resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

# Alarms for App Runner (dimension is ServiceName)
resource "aws_cloudwatch_metric_alarm" "apprunner_5xx" {
  alarm_name          = "${local.name_prefix}-5xx-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "5xx"
  namespace           = "AWS/AppRunner"
  period              = 60
  statistic           = "Sum"
  threshold           = 0
  treat_missing_data  = "notBreaching"

  dimensions = {
    ServiceName = aws_apprunner_service.app.service_name
  }

  alarm_description = "App Runner 5xx > 0"
  alarm_actions     = [aws_sns_topic.alerts.arn]
  ok_actions        = [aws_sns_topic.alerts.arn]
}

resource "aws_cloudwatch_metric_alarm" "apprunner_cpu" {
  alarm_name          = "${local.name_prefix}-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "CpuUtilization"
  namespace           = "AWS/AppRunner"
  period              = 60
  statistic           = "Average"
  threshold           = 80
  treat_missing_data  = "notBreaching"

  dimensions = {
    ServiceName = aws_apprunner_service.app.service_name
  }

  alarm_description = "CPU > 80%"
  alarm_actions     = [aws_sns_topic.alerts.arn]
  ok_actions        = [aws_sns_topic.alerts.arn]
}

resource "aws_cloudwatch_metric_alarm" "apprunner_mem" {
  alarm_name          = "${local.name_prefix}-mem-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "MemoryUtilization"
  namespace           = "AWS/AppRunner"
  period              = 60
  statistic           = "Average"
  threshold           = 80
  treat_missing_data  = "notBreaching"

  dimensions = {
    ServiceName = aws_apprunner_service.app.service_name
  }

  alarm_description = "Memory > 80%"
  alarm_actions     = [aws_sns_topic.alerts.arn]
  ok_actions        = [aws_sns_topic.alerts.arn]
}

# Dashboard
resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "${local.name_prefix}-dashboard"
  dashboard_body = jsonencode({
    widgets = [
      {
        "type" : "metric",
        "x" : 0, "y" : 0, "width" : 12, "height" : 6,
        "properties" : {
          "title" : "Requests / 4xx / 5xx",
          "metrics" : [
            ["AWS/AppRunner", "Requests", "ServiceName", aws_apprunner_service.app.service_name],
            [".", "4xx", ".", "."],
            [".", "5xx", ".", "."]
          ],
          "region" : var.region,
          "stat" : "Sum",
          "period" : 60,
          "stacked" : false
        }
      },
      {
        "type" : "metric",
        "x" : 12, "y" : 0, "width" : 12, "height" : 6,
        "properties" : {
          "title" : "Latency (P50/P90)",
          "metrics" : [
            ["AWS/AppRunner", "Latency", "ServiceName", aws_apprunner_service.app.service_name, { "stat" : "p50" }],
            [".", "Latency", ".", ".", { "stat" : "p90" }]
          ],
          "region" : var.region,
          "period" : 60
        }
      },
      {
        "type" : "metric",
        "x" : 0, "y" : 6, "width" : 12, "height" : 6,
        "properties" : {
          "title" : "CPU Utilization",
          "metrics" : [
            ["AWS/AppRunner", "CpuUtilization", "ServiceName", aws_apprunner_service.app.service_name]
          ],
          "region" : var.region,
          "stat" : "Average",
          "period" : 60
        }
      },
      {
        "type" : "metric",
        "x" : 12, "y" : 6, "width" : 12, "height" : 6,
        "properties" : {
          "title" : "Memory Utilization",
          "metrics" : [
            ["AWS/AppRunner", "MemoryUtilization", "ServiceName", aws_apprunner_service.app.service_name]
          ],
          "region" : var.region,
          "stat" : "Average",
          "period" : 60
        }
      }
    ]
  })
}

output "dashboard_name" {
  value = aws_cloudwatch_dashboard.main.dashboard_name
}

output "alerts_topic_arn" {
  value = aws_sns_topic.alerts.arn
}
