# Backend Lambda for MonsterNames API

This Lambda function serves as the backend for the read-only MonsterNames REST API, returning random fantasy monster names from the DynamoDB tables Terraform manages.

## Architecture

The Lambda is structured following best practices:

- **main.py** - Lambda handler entry point
- **config.py** - Configuration management (INI file parsing)
- **service.py** - Business logic for name operations
- **config.ini** - Endpoint to DynamoDB table mappings

## Features

- **GET requests**: Retrieve random monster names from DynamoDB
- **Read-only**: Other methods get a 405, and names change only through `application/seed_data/`
- **Comprehensive logging**: Structured logging with configurable levels
- **Type safety**: Full type hints throughout codebase
- **Error handling**: Explicit exception handling with proper logging

## Environment Variables

| Variable | Required | Description | Default |
|----------|----------|-------------|---------|
| `CONFIG_FILE` | Yes | Path to config.ini file | N/A |
| `LOG_LEVEL` | No | Logging level (DEBUG, INFO, WARNING, ERROR) | INFO |
| `DYNAMODB_ENDPOINT` | No | Custom DynamoDB endpoint (for local testing) | None |

## Building

```bash
./scripts/build-lambda.sh backend
```

This creates `lambda-packages/backend.zip` containing:
- Python code
- Dependencies from requirements.txt
- Configuration file

## Local Testing

Tests live in `tests/` at the repo root and mock DynamoDB with moto. From the repo root:

```bash
pip install -r requirements-dev.txt
pytest
```

## Code Quality

Follows [sudoblark.documentation Python standards](https://github.com/sudoblark/sudoblark.documentation):

- ✅ Explicit type hints on all functions and variables
- ✅ Google-style docstrings
- ✅ Comprehensive error handling
- ✅ Structured logging
- ✅ Clear separation of concerns (handler → config → service)

## API Usage

### GET Request
```bash
curl https://monsternames.sudoblark.com/skeleton
# Response: {"first_name": "Reginald", "last_name": "Montgomery", "full_name": "Reginald Montgomery"}
```

## Configuration Format

Each section maps a route to the Terraform-managed tables in `modules/data/dynamodb_tables.tf`:

```ini
[/skeleton]
first_name_table = aws-sudoblark-production-monsternames-api-skeleton-first-name
last_name_table = aws-sudoblark-production-monsternames-api-skeleton-last-name

[/orc]
first_name_table = aws-sudoblark-production-monsternames-api-orc-first-name
last_name_table = aws-sudoblark-production-monsternames-api-orc-last-name
```

## Dependencies

- **boto3** - AWS SDK for DynamoDB operations
- **aws-lambda-powertools** - Structured event parsing and utilities
