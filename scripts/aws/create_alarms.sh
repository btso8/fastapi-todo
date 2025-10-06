#!/usr/bin/env bash
set -euo pipefail
# Create basic App Runner alarms (error rate %, p90 latency).
# Usage: create_alarms.sh <service_name> <region> [sns_topic_arn]
SVC="${1:?service name required}"
REGION="${2:?region required}"
SNS="${3:-}"

echo "Creating/Updating alarms in $REGION for $SVC"

tmpdir=$(mktemp -d)

# Error rate % over 5 minutes (>1%)
cat > "$tmpdir/error_rate.json" <<JSON
{
  "AlarmName": "apprunner-error-rate-high",
  "AlarmDescription": "Error rate (4xx+5xx)/Requests > 1% (5m)",
  "ComparisonOperator": "GreaterThanThreshold",
  "EvaluationPeriods": 5,
  "Threshold": 1.0,
  "TreatMissingData": "notBreaching",
  "Metrics": [
    { "Id":"req","MetricStat":{"Metric":{"Namespace":"AWS/AppRunner","MetricName":"Requests","Dimensions":[{"Name":"ServiceName","Value":"$SVC"}]},"Period":60,"Stat":"Sum"},"ReturnData":false},
    { "Id":"m4","MetricStat":{"Metric":{"Namespace":"AWS/AppRunner","MetricName":"4xxStatusResponses","Dimensions":[{"Name":"ServiceName","Value":"$SVC"}]},"Period":60,"Stat":"Sum"},"ReturnData":false},
    { "Id":"m5","MetricStat":{"Metric":{"Namespace":"AWS/AppRunner","MetricName":"5xxStatusResponses","Dimensions":[{"Name":"ServiceName","Value":"$SVC"}]},"Period":60,"Stat":"Sum"},"ReturnData":false},
    { "Id":"er","Expression":"(m4 + m5) / IF(req, req, 1) * 100","Label":"ErrorRatePercent","ReturnData":true}
  ]
}
JSON

# p90 latency > 300ms over 5 minutes
cat > "$tmpdir/latency_p90.json" <<JSON
{
  "AlarmName": "apprunner-latency-p90-high",
  "AlarmDescription": "RequestLatency p90 > 300ms (5m)",
  "ComparisonOperator": "GreaterThanThreshold",
  "EvaluationPeriods": 5,
  "Threshold": 300.0,
  "TreatMissingData": "notBreaching",
  "Metrics": [
    { "Id":"lat","MetricStat":{"Metric":{"Namespace":"AWS/AppRunner","MetricName":"RequestLatency","Dimensions":[{"Name":"ServiceName","Value":"$SVC"}]},"Period":60,"Stat":"p90"},"ReturnData":true}
  ]
}
JSON

put_alarm() {
  local file="$1"
  if [ -n "$SNS" ]; then
    aws cloudwatch put-metric-alarm --region "$REGION" \
      --cli-input-json "file://$file" \
      --alarm-actions "$SNS" --ok-actions "$SNS"
  else
    aws cloudwatch put-metric-alarm --region "$REGION" \
      --cli-input-json "file://$file"
  fi
}

put_alarm "$tmpdir/error_rate.json"
put_alarm "$tmpdir/latency_p90.json"

echo "Done: apprunner-error-rate-high, apprunner-latency-p90-high"
