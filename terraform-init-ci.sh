#!/bin/bash
set -ex

#getValeurFromTfvars() { grep "$1[[:space:]]*=" "tfvars/$ENV.tfvars" | awk -F'=' '{ gsub("\"| ","", $2); print $2}' ; }
getValeurFromGlobalTFVars() { grep "$1[[:space:]]*=" "global.auto.tfvars" | awk -F'=' '{ gsub("\"| ","", $2); print $2}' ; }

APPLICATION=$(getValeurFromGlobalTFVars application)
REGION=$(getValeurFromGlobalTFVars region)

export APPLICATION
export REGION

terraform init \
 -reconfigure \
 -backend-config="bucket=hymaia-tfstate-${ENV}-digipoc" \
 -backend-config="key=${APPLICATION}/${REGION}/${ENV}/terraform.tfstate" \
 -backend-config="dynamodb_table=terraform-lock-${ENV}"
