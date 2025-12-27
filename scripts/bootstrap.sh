#!/bin/bash
set -e
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
else
    echo "📦 Creating State Bucket: gs://$BUCKET_NAME"
    gcloud storage buckets create "gs://$BUCKET_NAME" --project="$PROJECT_ID" --location="us-central1"
    gcloud storage buckets update "gs://$BUCKET_NAME" --versioning
fi