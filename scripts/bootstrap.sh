#!/bin/bash
set -e

PROJECT_ID=$1
REGION="us-central1"
BUCKET_NAME="${PROJECT_ID}-tf-state"

echo "🚀 Enabling Cloud APIs for $PROJECT_ID..."
gcloud services enable \
    iam.googleapis.com \
    cloudresourcemanager.googleapis.com \
    sts.googleapis.com \
    iamcredentials.googleapis.com \
    compute.googleapis.com \
    container.googleapis.com --project=$PROJECT_ID

if gsutil ls -p $PROJECT_ID gs://$BUCKET_NAME > /dev/null 2>&1; then
    echo "✅ State Bucket already exists."
else
    echo "📦 Creating State Bucket: gs://$BUCKET_NAME"
    gsutil mb -p $PROJECT_ID -l $REGION gs://$BUCKET_NAME
    gsutil versioning set on gs://$BUCKET_NAME
fi