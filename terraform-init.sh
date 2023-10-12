#!/bin/bash
set -ex

#caller gives
#TF_VAR_region
#TF_VAR_dom_shortname

#getValeurFromTfvars() { grep "$1[[:space:]]*=" "tfvars/$ENV.tfvars" | awk -F'=' '{ gsub("\"| ","", $2); print $2}' ; }
getValeurFromGlobalTFVars() { grep "$1[[:space:]]*=" "global.auto.tfvars" | awk -F'=' '{ gsub("\"| ","", $2); print $2}' ; }

APPLICATION=$(getValeurFromGlobalTFVars application)
REGION=$(getValeurFromGlobalTFVars region)

export APPLICATION
export REGION

tfenv install

# -var-file=tfvars/"${ENV}".tfvars \

terraform init \
 -reconfigure \
 -backend-config="bucket=hymaia-tfstate-${ENV}-digipoc" \
 -backend-config="key=${APPLICATION}/${REGION}/${ENV}/terraform.tfstate" \
 -backend-config="dynamodb_table=terraform-lock-${ENV}" \
 -backend-config="profile=${AWS_PROFILE}"
