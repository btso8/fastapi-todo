REGION=eu-west-2
SERVICE=apprunner-todo
TOPIC_ARN=arn:aws:sns:eu-west-2:975705622152:apprunner-alerts  # or leave blank

# Create temp folder
TMP=$(mktemp -d)
cd "$TMP"

# Error-rate alarm JSON (metric math: (4xx+5xx)/Requests * 100)
cat > error_rate_alarm.json <<'JSON'
{
  "AlarmName": "apprunner-error-rate-high",
  "AlarmDescription": "App Runner error rate > threshold",
  "ComparisonOperator": "GreaterThanThreshold",
  "EvaluationPeriods": 3,
  "Threshold": 1.0,
  "TreatMissingData": "notBreaching",
  "Metrics": [
    {
      "Id": "m_requests",
      "MetricStat": {
        "Metric": {
          "Namespace": "AWS/AppRunner",
          "MetricName": "Requests",
          "Dimensions": [{ "Name": "ServiceName", "Value": "REPLACE_SERVICE_NAME" }]
        },
        "Period": 60,
        "Stat": "Sum"
      },
      "ReturnData": false
    },
    {
      "Id": "m_4xx",
      "MetricStat": {
        "Metric": {
          "Namespace": "AWS/AppRunner",
          "MetricName": "4xxStatusResponses",
          "Dimensions": [{ "Name": "ServiceName", "Value": "REPLACE_SERVICE_NAME" }]
        },
        "Period": 60,
        "Stat": "Sum"
      },
      "ReturnData": false
    },
    {
      "Id": "m_5xx",
      "MetricStat": {
        "Metric": {
          "Namespace": "AWS/AppRunner",
          "MetricName": "5xxStatusResponses",
          "Dimensions": [{ "Name": "ServiceName", "Value": "REPLACE_SERVICE_NAME" }]
        },
        "Period": 60,
        "Stat": "Sum"
      },
      "ReturnData": false
    },
    {
      "Id": "e_error_rate",
      "Expression": "(m_4xx + m_5xx) / IF(m_requests, m_requests, 1) * 100",
      "Label": "ErrorRatePercent",
      "ReturnData": true
    }
  ]
}
JSON

# p90 latency alarm JSON
cat > latency_p90_alarm.json <<'JSON'
{
  "AlarmName": "apprunner-latency-p90-high",
  "AlarmDescription": "App Runner p90 RequestLatency high",
  "ComparisonOperator": "GreaterThanThreshold",
  "EvaluationPeriods": 3,
  "Threshold": 300.0,
  "TreatMissingData": "notBreaching",
  "Metrics": [
    {
      "Id": "m_latency_p90",
      "MetricStat": {
        "Metric": {
          "Namespace": "AWS/AppRunner",
          "MetricName": "RequestLatency",
          "Dimensions": [{ "Name": "ServiceName", "Value": "REPLACE_SERVICE_NAME" }]
        },
        "Period": 60,
        "Stat": "p90"
      },
      "ReturnData": true
    }
  ]
}
JSON

# Inject your service name
sed -i "s/REPLACE_SERVICE_NAME/${SERVICE}/g" error_rate_alarm.json latency_p90_alarm.json

# Create the alarms (with optional SNS actions if you set TOPIC_ARN)
if [ -n "$TOPIC_ARN" ]; then
  aws cloudwatch put-metric-alarm --region "$REGION" \
    --cli-input-json file://latency_p90_alarm.json \
    --alarm-actions "$TOPIC_ARN" --ok-actions "$TOPIC_ARN"

  aws cloudwatch put-metric-alarm --region "$REGION" \
    --cli-input-json file://error_rate_alarm.json \
    --alarm-actions "$TOPIC_ARN" --ok-actions "$TOPIC_ARN"
else
  aws cloudwatch put-metric-alarm --region "$REGION" --cli-input-json file://latency_p90_alarm.json
  aws cloudwatch put-metric-alarm --region "$REGION" --cli-input-json file://error_rate_alarm.json
fi
