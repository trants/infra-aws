#!/bin/bash
# Script to setup Terraform backend (S3 bucket + DynamoDB table)
# Usage: ./setup-backend.sh [region]

set -e

REGION="${1:-us-east-1}"
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

if [ -z "$ACCOUNT_ID" ]; then
  echo "Error: Could not get AWS Account ID. Make sure AWS CLI is configured."
  exit 1
fi

BUCKET_NAME="terraform-state-${ACCOUNT_ID}-${REGION}"
DYNAMODB_TABLE="terraform-state-lock"

echo "=========================================="
echo "Setting up Terraform Backend"
echo "=========================================="
echo "Account ID: ${ACCOUNT_ID}"
echo "Region: ${REGION}"
echo "Bucket Name: ${BUCKET_NAME}"
echo "DynamoDB Table: ${DYNAMODB_TABLE}"
echo "=========================================="
echo ""

# Check if bucket already exists
if aws s3 ls "s3://${BUCKET_NAME}" 2>/dev/null; then
  echo "⚠️  Bucket ${BUCKET_NAME} already exists. Skipping bucket creation."
else
  echo "📦 Creating S3 bucket: ${BUCKET_NAME}"
  aws s3 mb "s3://${BUCKET_NAME}" --region "${REGION}"
  
  echo "✅ Enabling versioning..."
  aws s3api put-bucket-versioning \
    --bucket "${BUCKET_NAME}" \
    --versioning-configuration Status=Enabled
  
  echo "🔒 Enabling encryption..."
  aws s3api put-bucket-encryption \
    --bucket "${BUCKET_NAME}" \
    --server-side-encryption-configuration '{
      "Rules": [{
        "ApplyServerSideEncryptionByDefault": {
          "SSEAlgorithm": "AES256"
        }
      }]
    }'
  
  echo "🛡️  Blocking public access..."
  aws s3api put-public-access-block \
    --bucket "${BUCKET_NAME}" \
    --public-access-block-configuration \
      "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"
  
  echo "✅ Bucket ${BUCKET_NAME} created and configured!"
fi

echo ""

# Check if DynamoDB table already exists
if aws dynamodb describe-table --table-name "${DYNAMODB_TABLE}" --region "${REGION}" 2>/dev/null; then
  echo "⚠️  DynamoDB table ${DYNAMODB_TABLE} already exists. Skipping table creation."
else
  echo "🗄️  Creating DynamoDB table: ${DYNAMODB_TABLE}"
  aws dynamodb create-table \
    --table-name "${DYNAMODB_TABLE}" \
    --attribute-definitions AttributeName=LockID,AttributeType=S \
    --key-schema AttributeName=LockID,KeyType=HASH \
    --billing-mode PAY_PER_REQUEST \
    --region "${REGION}" \
    > /dev/null
  
  echo "⏳ Waiting for table to be active..."
  aws dynamodb wait table-exists --table-name "${DYNAMODB_TABLE}" --region "${REGION}"
  echo "✅ DynamoDB table ${DYNAMODB_TABLE} created!"
fi

echo ""
echo "=========================================="
echo "✅ Backend setup complete!"
echo "=========================================="
echo ""
echo "Next steps:"
echo "1. Copy backend.hcl.example to backend.hcl:"
echo "   cp backend.hcl.example backend.hcl"
echo ""
echo "2. Update backend.hcl with your bucket name:"
echo "   bucket = \"${BUCKET_NAME}\""
echo ""
echo "3. Initialize Terraform:"
echo "   terraform init -backend-config=backend.hcl"
echo ""

