#!/bin/bash
#
# Build Lambda deployment packages
#
# Usage: ./build-lambda.sh <lambda-name>
#
# Example: ./build-lambda.sh backend
#

set -e

LAMBDA_NAME="${1}"

if [ -z "${LAMBDA_NAME}" ]; then
  echo "Error: Lambda name required"
  echo "Usage: $0 <lambda-name>"
  echo "Example: $0 backend"
  exit 1
fi

# Source lives in application/lambda, and the built zip in lambda-packages,
# where modules/data/lambdas.tf expects it
LAMBDA_DIR="./application/lambda/${LAMBDA_NAME}"
OUTPUT_DIR="$(pwd)/lambda-packages"
OUTPUT_ZIP="${OUTPUT_DIR}/${LAMBDA_NAME}.zip"

if [ ! -d "${LAMBDA_DIR}" ]; then
  echo "Error: Lambda directory '${LAMBDA_DIR}' does not exist"
  exit 1
fi

echo "======================================"
echo "Building Lambda: ${LAMBDA_NAME}"
echo "======================================"
echo ""

# Clean up previous build
mkdir -p "${OUTPUT_DIR}"
if [ -f "${OUTPUT_ZIP}" ]; then
  echo "Removing existing package: ${OUTPUT_ZIP}"
  rm "${OUTPUT_ZIP}"
fi

# Create temporary build directory
BUILD_DIR=$(mktemp -d)
echo "Using temporary build directory: ${BUILD_DIR}"

# Copy Lambda code. Its dependencies come from AWS, not the package: boto3
# from the Python runtime and Powertools from the layer in
# modules/data/lambdas.tf.
echo "Copying Lambda code..."
cp "${LAMBDA_DIR}"/*.py "${BUILD_DIR}/"

# Create ZIP package
echo "Creating deployment package..."
cd "${BUILD_DIR}"
zip -r9 "${OUTPUT_ZIP}" . -q
cd - > /dev/null

# Clean up
rm -rf "${BUILD_DIR}"

# Show package info
PACKAGE_SIZE=$(du -h "${OUTPUT_ZIP}" | cut -f1)
echo ""
echo "======================================"
echo "Build Complete!"
echo "======================================"
echo "Package: ${OUTPUT_ZIP}"
echo "Size: ${PACKAGE_SIZE}"
echo ""
echo "To deploy:"
echo "  cd infrastructure/aws-sudoblark-production"
echo "  terraform apply"
