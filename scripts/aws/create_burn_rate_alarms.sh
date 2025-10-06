#!/usr/bin/env bash
set -euo pipefail
# Usage: create_burn_rate_alarms.sh <service_name> <region> [sns_topic_arn]
SVC="${1:?service name required}"
REGION="${2:?region required}"
SNS="${3:-}"

echo "Creating burn-rate + burst alarms for $SVC in $REGION"
tmpdir=$(mktemp -d)

# Fast burn (~5m) > 5%
cat > "$tmpdir/err_fast.json" <<JSON
{
  "AlarmName": "apprunner-error-burn-fast",
  "AlarmDescription": "Fast burn: error rate > 5% (~5m)",
  "ComparisonOperator": "GreaterThanThreshold",
  "EvaluationPeriods": 5,
  "Threshold": 5.0,
  "TreatMissingData": "notBreaching",
  "Metrics": [
    { "Id":"req","MetricStat":{"Metric":{"Namespace":"AWS/AppRunner","MetricName":"Requests","Dimensions":[{"Name":"ServiceName","Value":"$SVC"}]},"Period":60,"Stat":"Sum"},"ReturnData":false},
    { "Id":"m4","MetricStat":{"Metric":{"Namespace":"AWS/AppRunner","MetricName":"4xxStatusResponses","Dimensions":[{"Name":"ServiceName","Value":"$SVC"}]},"Period":60,"Stat":"Sum"},"ReturnData":false},
    { "Id":"m5","MetricStat":{"Metric":{"Namespace":"AWS/AppRunner","MetricName":"5xxStatusResponses","Dimensions":[{"Name":"ServiceName","Value":"$SVC"}]},"Period":60,"Stat":"Sum"},"ReturnData":false},
    { "Id":"er","Expression":"(m4 + m5) / IF(req, req, 1) * 100","Label":"ErrorRatePercent","ReturnData":true}
  ]
}
JSON

# Slow burn (~60m) > 1%
cat > "$tmpdir/err_slow.json" <<JSON
{
  "AlarmName": "apprunner-error-burn-slow",
  "AlarmDescription": "Slow burn: error rate > 1% (~60m)",
  "ComparisonOperator": "GreaterThanThreshold",
  "EvaluationPeriods": 12,
  "Threshold": 1.0,
  "TreatMissingData": "notBreaching",
  "Metrics": [
    { "Id":"req","MetricStat":{"Metric":{"Namespace":"AWS/AppRunner","MetricName":"Requests","Dimensions":[{"Name":"ServiceName","Value":"$SVC"}]},"Period":300,"Stat":"Sum"},"ReturnData":false},
    { "Id":"m4","MetricStat":{"Metric":{"Namespace":"AWS/AppRunner","MetricName":"4xxStatusResponses","Dimensions":[{"Name":"ServiceName","Value":"$SVC"}]},"Period":300,"Stat":"Sum"},"ReturnData":false},
    { "Id":"m5","MetricStat":{"Metric":{"Namespace":"AWS/AppRunner","MetricName":"5xxStatusResponses","Dimensions":[{"Name":"ServiceName","Value":"$SVC"}]},"Period":300,"Stat":"Sum"},"ReturnData":false},
    { "Id":"er","Expression":"(m4 + m5) / IF(req, req, 1) * 100","Label":"ErrorRatePercent","ReturnData":true}
  ]
}
JSON

# 5xx burst (>=1 in 1m)
cat > "$tmpdir/5xx_burst.json" <<JSON
{
  "AlarmName": "apprunner-5xx-burst",
  "AlarmDescription": "Any 5xx in last minute",
  "ComparisonOperator": "GreaterThanOrEqualToThreshold",
  "EvaluationPeriods": 1,
  "Threshold": 1.0,
  "TreatMissingData": "notBreaching",
  "MetricName": "5xxStatusResponses",
  "Namespace": "AWS/AppRunner",
  "Period": 60,
  "Statistic": "Sum",
  "Dimensions": [{ "Name":"ServiceName","Value":"$SVC" }]
}
JSON

create_alarm() {
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

create_alarm "$tmpdir/err_fast.json"
create_alarm "$tmpdir/err_slow.json"
create_alarm "$tmpdir/5xx_burst.json"

echo "Done: apprunner-error-burn-fast, apprunner-error-burn-slow, apprunner-5xx-burst"
