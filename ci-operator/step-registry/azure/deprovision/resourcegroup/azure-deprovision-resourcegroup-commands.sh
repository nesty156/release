#!/bin/bash

set -o nounset
set -o errexit
set -o pipefail

# az should already be there
command -v az
az --version

# set the parameters we'll need as env vars
AZURE_AUTH_LOCATION="${CLUSTER_PROFILE_DIR}/osServicePrincipal.json"
AZURE_AUTH_CLIENT_ID="$(<"${AZURE_AUTH_LOCATION}" jq -r .clientId)"
AZURE_AUTH_CLIENT_SECRET="$(<"${AZURE_AUTH_LOCATION}" jq -r .clientSecret)"
AZURE_AUTH_TENANT_ID="$(<"${AZURE_AUTH_LOCATION}" jq -r .tenantId)"

# log in with az
if [[ "${CLUSTER_TYPE}" == "azuremag" ]]; then
    az cloud set --name AzureUSGovernment
else
    az cloud set --name AzureCloud
fi
az login --service-principal -u "${AZURE_AUTH_CLIENT_ID}" -p "${AZURE_AUTH_CLIENT_SECRET}" --tenant "${AZURE_AUTH_TENANT_ID}" --output none

remove_resources_by_cli="${SHARED_DIR}/remove_resources_by_cli.sh"
if [ -f "${remove_resources_by_cli}" ]; then
    sh -x "${remove_resources_by_cli}"
fi

rg_file="${SHARED_DIR}/resouregroup"
if [ -f "${rg_file}" ]; then
    existing_rg=$(cat "${rg_file}")
    if [ "$(az group exists -n "${existing_rg}")" == "true" ]; then
	az group delete -y -n "${existing_rg}"
    fi
fi
