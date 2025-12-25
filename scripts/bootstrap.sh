#!/bin/bash
set -e

PROJECT_ID=$1
REGION="us-central1"
BUCKET_NAME="${PROJECT_ID}-tf-state"

echo "🚀 Enabling Cloud APIs for $PROJECT_ID..."
gcloud services enable \
    cloudresourcemanager.googleapis.com \
    iam.googleapis.com \
    sts.googleapis.com \
    iamcredentials.googleapis.com \
    compute.googleapis.com \
    container.googleapis.com --project="$PROJECT_ID"

# Use 'gcloud storage' instead of 'gsutil' for native auth integration
if gcloud storage buckets describe "gs://$BUCKET_NAME" --project="$PROJECT_ID" > /dev/null 2>&1; then
    echo "✅ State Bucket already exists."
else
    echo "📦 Creating State Bucket: gs://$BUCKET_NAME"
    gcloud storage buckets create "gs://$BUCKET_NAME" \
        --project="$PROJECT_ID" \
        --location="$REGION" \
        --uniform-bucket-level-access
    
    # Enable versioning for state safety
    gcloud storage buckets update "gs://$BUCKET_NAME" --versioning
fi