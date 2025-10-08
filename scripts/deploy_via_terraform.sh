#!/usr/bin/env bash
set -euo pipefail
terraform -chdir=terraform-ecs init
terraform -chdir=terraform-ecs apply -auto-approve
