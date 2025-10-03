aws cloudwatch set-alarm-state \
  --alarm-name "AppRunner-5xx-High-apprunner-todo" \
  --state-value ALARM \
  --state-reason "Test alarm"

# Reset:
aws cloudwatch set-alarm-state \
  --alarm-name "AppRunner-5xx-High-apprunner-todo" \
  --state-value OK \
  --state-reason "Reset after test"
