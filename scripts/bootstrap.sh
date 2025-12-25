#!/bin/bash
set -e

# Project configuration from GitHub variables
PROJECT_ID=$1
REGION="us-central1"
BUCKET_NAME="${PROJECT_ID}-tf-state"

if [ -z "$PROJECT_ID" ]; then
    echo "❌ Error: Project ID is required."
    exit 1
fi

echo "🚀 Bootstrapping Cloud Foundation for $PROJECT_ID..."

# Step 1: Wake up the required Cloud APIs
# We enable Cloud Resource Manager first so we can manage other services
gcloud services enable \
    cloudresourcemanager.googleapis.com \
    iam.googleapis.com \
    sts.googleapis.com \
    iamcredentials.googleapis.com \
    compute.googleapis.com \
    container.googleapis.com --project="$PROJECT_ID"

# Step 2: Create the GCS Bucket for Terraform Remote State
# We use the -p flag to force gsutil to use the correct project credentials
if gsutil -p "$PROJECT_ID" ls "gs://$BUCKET_NAME" > /dev/null 2>&1; then
    echo "✅ State Bucket already exists."
else
    echo "📦 Creating State Bucket: gs://$BUCKET_NAME"
    gsutil mb -p "$PROJECT_ID" -c standard -l "$REGION" "gs://$BUCKET_NAME"
    
    # Enable versioning so you can recover from accidental deletions
    gsutil versioning set on "gs://$BUCKET_NAME"
fi

echo "⭐ Bootstrap Complete! Your cloud 'Brain' is now active."