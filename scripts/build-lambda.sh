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

LAMBDA_DIR="./lambda-packages/${LAMBDA_NAME}"
OUTPUT_ZIP="$(pwd)/lambda-packages/${LAMBDA_NAME}.zip"

if [ ! -d "${LAMBDA_DIR}" ]; then
  echo "Error: Lambda directory '${LAMBDA_DIR}' does not exist"
  exit 1
fi

echo "======================================"
echo "Building Lambda: ${LAMBDA_NAME}"
echo "======================================"
echo ""

# Clean up previous build
if [ -f "${OUTPUT_ZIP}" ]; then
  echo "Removing existing package: ${OUTPUT_ZIP}"
  rm "${OUTPUT_ZIP}"
fi

# Create temporary build directory
BUILD_DIR=$(mktemp -d)
echo "Using temporary build directory: ${BUILD_DIR}"

# Install dependencies
if [ -f "${LAMBDA_DIR}/requirements.txt" ]; then
  echo "Installing dependencies..."
  pip install -r "${LAMBDA_DIR}/requirements.txt" -t "${BUILD_DIR}" --quiet
  echo "✓ Dependencies installed"
else
  echo "⚠ No requirements.txt found, skipping dependency installation"
fi

# Copy Lambda code
echo "Copying Lambda code..."
if [ -d "${LAMBDA_DIR}/backend_lambda" ]; then
  cp -r "${LAMBDA_DIR}/backend_lambda" "${BUILD_DIR}/"
fi

# Copy configuration files
if [ -f "${LAMBDA_DIR}/config.ini" ]; then
  cp "${LAMBDA_DIR}/config.ini" "${BUILD_DIR}/"
  echo "✓ Copied config.ini"
fi

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
