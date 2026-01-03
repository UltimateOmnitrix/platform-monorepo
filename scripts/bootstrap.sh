#!/bin/bash
# -----------------------------------------------------------------------------
# Bootstrap Script – GCP Project Initialization
#
# Purpose:
# This script performs one-time bootstrap operations required before running
# Terraform. 
# It enables mandatory Google Cloud APIs and provisions a
# versioned Cloud Storage bucket used as the Terraform remote backend.
#
# Usage:
#   ./bootstrap.sh <GCP_PROJECT_ID>
#
# Notes:
# - This script is safe to re-run and is idempotent.
# - It must be executed with sufficient permissions to manage GCP services
#   and Cloud Storage resources.
# - This script should be run only during initial project setup.
# -----------------------------------------------------------------------------


# this tells the script to urn using Bash  THE BELOW IS NOT A COMMENT OK!!!
#!/bin/bash

# the set -e applies to entire script if any of the cmd fails
# in this script the entire execution stops 
set -e

# We have passed the argument from the 00-bootstrap-foundation.yml workflow
# as ./scripts/bootstrap.sh "${{ vars.GCP_PROJECT_ID }}" 
# so the $1 in here it mean to pick up the first argument
PROJECT_ID=$1
BUCKET_NAME="${PROJECT_ID}-tf-state"

echo "🚀 Enabling Cloud APIs for $PROJECT_ID..."
gcloud services enable \
    cloudresourcemanager.googleapis.com \
    iam.googleapis.com \
    sts.googleapis.com \
    iamcredentials.googleapis.com \
    compute.googleapis.com --project="$PROJECT_ID"

# Use gcloud storage for native authentication integration
if gcloud storage buckets describe "gs://$BUCKET_NAME" --project="$PROJECT_ID" > /dev/null 2>&1; then
    echo "✅ State Bucket exists."
    echo "✅ the execution of bootstrap.sh is completed"
else
    echo "📦 Creating State Bucket: gs://$BUCKET_NAME"
    gcloud storage buckets create "gs://$BUCKET_NAME" --project="$PROJECT_ID" --location="us-central1"
    gcloud storage buckets update "gs://$BUCKET_NAME" --versioning
    echo "✅ the execution of bootstrap.sh is completed"
fi