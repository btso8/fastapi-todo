#!/usr/bin/env bash
set -euo pipefail

#############################################
# 🔧 EDIT THESE FOR YOUR ACCOUNT/SERVICE
#############################################
AWS_REGION="eu-west-2"
SERVICE_NAME="fastapi-todo"   # only used if SERVICE_ARN is blank; final name is read from ARN
RDS_DB_ID="todo-db"
ALERT_EMAIL="brandonoliver@live.co.uk"
SNS_TOPIC_NAME="apprunner-alerts"
LOG_RETENTION_DAYS=14
# If you know the service ARN already, paste it; otherwise leave blank to resolve by name
SERVICE_ARN="arn:aws:apprunner:eu-west-2:975705622152:service/apprunner-todo/6a6bef99062b4f7db505f384eb6865aa"

#############################################
# Environment / region
#############################################
aws configure set region "${AWS_REGION}"
export AWS_DEFAULT_REGION="${AWS_REGION}"

echo "== Region:           ${AWS_REGION}"
echo "== Preferred name:   ${SERVICE_NAME}"
echo "== RDS instance id:  ${RDS_DB_ID}"
echo "== Alerts email:     ${ALERT_EMAIL}"
echo "== SNS topic:        ${SNS_TOPIC_NAME}"
echo

#############################################
# 0) Resolve App Runner Service ARN (if not provided)
#############################################
if [[ -z "${SERVICE_ARN}" || "${SERVICE_ARN}" == "<YOUR_SERVICE_ARN>" ]]; then
  echo "Resolving App Runner service ARN for ${SERVICE_NAME}…"
  SERVICE_ARN=$(aws apprunner list-services \
    --query "ServiceSummaryList[?ServiceName=='${SERVICE_NAME}'].ServiceArn | [0]" \
    --output text)
  if [[ -z "${SERVICE_ARN}" || "${SERVICE_ARN}" == "None" ]]; then
    echo "❌ Could not find an App Runner service named '${SERVICE_NAME}'."
    echo "    - Double-check the name, or set SERVICE_ARN explicitly at the top."
    exit 1
  fi
fi
echo "== Service ARN: ${SERVICE_ARN}"

# Derive actual ServiceName + ServiceId (authoritative)
read SERVICE_NAME_RESOLVED SERVICE_ID < <(
  aws apprunner describe-service \
    --service-arn "${SERVICE_ARN}" \
    --query 'Service.[ServiceName,ServiceId]' \
    --output text
)

LOG_APP="/aws/apprunner/${SERVICE_NAME_RESOLVED}/${SERVICE_ID}/application"
LOG_SVC="/aws/apprunner/${SERVICE_NAME_RESOLVED}/${SERVICE_ID}/service"

echo "== Service name:     ${SERVICE_NAME_RESOLVED}"
echo "== Service id:       ${SERVICE_ID}"
echo "== Log (application): ${LOG_APP}"
echo "== Log (service):     ${LOG_SVC}"
echo

#############################################
# 1) CloudWatch log retention
#############################################
echo "Ensuring CloudWatch log groups exist…"
aws logs create-log-group --log-group-name "${LOG_APP}" 2>/dev/null || true
aws logs create-log-group --log-group-name "${LOG_SVC}" 2>/dev/null || true

echo "Setting retention to ${LOG_RETENTION_DAYS} days…"
aws logs put-retention-policy --log-group-name "${LOG_APP}" --retention-in-days "${LOG_RETENTION_DAYS}" || true
aws logs put-retention-policy --log-group-name "${LOG_SVC}" --retention-in-days "${LOG_RETENTION_DAYS}" || true
echo "✔ Log retention updated."
echo

#############################################
# 2) SNS topic + email subscription
#############################################
echo "Creating/using SNS topic '${SNS_TOPIC_NAME}'…"
TOPIC_ARN=$(aws sns create-topic --name "${SNS_TOPIC_NAME}" --query TopicArn --output text)
echo "== SNS Topic ARN: ${TOPIC_ARN}"

echo "Subscribing ${ALERT_EMAIL} to ${TOPIC_ARN}…"
aws sns subscribe \
  --topic-arn "${TOPIC_ARN}" \
  --protocol email \
  --notification-endpoint "${ALERT_EMAIL}" >/dev/null || true
echo "✔ Check your email and CONFIRM the SNS subscription (required to receive alerts)."
echo

#############################################
# 3) App Runner CPU & Memory alarms
#############################################
echo "Creating App Runner CPU > 80% alarm…"
aws cloudwatch put-metric-alarm \
  --alarm-name "AppRunner-CPU-High-${SERVICE_NAME_RESOLVED}" \
  --metric-name CpuUtilization \
  --namespace "AWS/AppRunner" \
  --dimensions Name=ServiceArn,Value="${SERVICE_ARN}" \
  --statistic Average --period 300 --evaluation-periods 1 \
  --threshold 80 --comparison-operator GreaterThanThreshold \
  --treat-missing-data notBreaching \
  --alarm-actions "${TOPIC_ARN}"

echo "Creating App Runner Memory > 80% alarm…"
aws cloudwatch put-metric-alarm \
  --alarm-name "AppRunner-Memory-High-${SERVICE_NAME_RESOLVED}" \
  --metric-name MemoryUtilization \
  --namespace "AWS/AppRunner" \
  --dimensions Name=ServiceArn,Value="${SERVICE_ARN}" \
  --statistic Average --period 300 --evaluation-periods 1 \
  --threshold 80 --comparison-operator GreaterThanThreshold \
  --treat-missing-data notBreaching \
  --alarm-actions "${TOPIC_ARN}"
echo "✔ App Runner CPU/Memory alarms created."
echo

#############################################
# 4) Log-based 5xx alarm (via metric filter)
#############################################
echo "Creating log metric filter for 5xx on ${LOG_SVC}…"
aws logs put-metric-filter \
  --log-group-name "${LOG_SVC}" \
  --filter-name "App5xx-${SERVICE_NAME_RESOLVED}" \
  --filter-pattern '{ $.status_code >= 500 }' \
  --metric-transformations metricName="App5xx-${SERVICE_NAME_RESOLVED}",metricNamespace="AppRunner",metricValue=1,defaultValue=0 || true

echo "Creating CloudWatch Alarm for >=5 5xx in 5 minutes…"
aws cloudwatch put-metric-alarm \
  --alarm-name "AppRunner-5xx-High-${SERVICE_NAME_RESOLVED}" \
  --namespace "AppRunner" \
  --metric-name "App5xx-${SERVICE_NAME_RESOLVED}" \
  --statistic Sum \
  --period 300 \
  --evaluation-periods 1 \
  --threshold 5 \
  --comparison-operator GreaterThanOrEqualToThreshold \
  --treat-missing-data notBreaching \
  --alarm-actions "${TOPIC_ARN}"
echo "✔ Log-based 5xx alarm created."
echo

# Fallback example (plain text logs):
# aws logs put-metric-filter \
#   --log-group-name "${LOG_SVC}" \
#   --filter-name "App5xxText-${SERVICE_NAME_RESOLVED}" \
#   --filter-pattern '" 5"' \
#   --metric-transformations metricName="App5xxText-${SERVICE_NAME_RESOLVED}",metricNamespace="AppRunner",metricValue=1,defaultValue=0

#############################################
# 5) RDS alarms (storage + connections)
#############################################
if [[ -n "${RDS_DB_ID}" && "${RDS_DB_ID}" != "<YOUR_RDS_INSTANCE_ID>" ]]; then
  echo "Creating RDS alarms (instance: ${RDS_DB_ID})…"

  # Free storage < 10 GB
  aws cloudwatch put-metric-alarm \
    --alarm-name "RDS-FreeStorage-Low-${RDS_DB_ID}" \
    --namespace AWS/RDS --metric-name FreeStorageSpace \
    --dimensions Name=DBInstanceIdentifier,Value="${RDS_DB_ID}" \
    --statistic Average --period 300 --evaluation-periods 1 \
    --threshold 10737418240 --comparison-operator LessThanThreshold \
    --treat-missing-data notBreaching \
    --alarm-actions "${TOPIC_ARN}"

  # DB connections > 80
  aws cloudwatch put-metric-alarm \
    --alarm-name "RDS-DBConnections-High-${RDS_DB_ID}" \
    --namespace AWS/RDS --metric-name DatabaseConnections \
    --dimensions Name=DBInstanceIdentifier,Value="${RDS_DB_ID}" \
    --statistic Average --period 300 --evaluation-periods 1 \
    --threshold 80 --comparison-operator GreaterThanThreshold \
    --treat-missing-data notBreaching \
    --alarm-actions "${TOPIC_ARN}"
  echo "✔ RDS alarms created."
else
  echo "⚠ Skipping RDS alarms (RDS_DB_ID not set)."
fi

echo
echo "✅ Done. Alarms will notify ${ALERT_EMAIL} (after you confirm the SNS email)."
echo "You can tweak thresholds by re-running this script with different values."
