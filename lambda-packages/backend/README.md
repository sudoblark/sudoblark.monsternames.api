# Backend Lambda for MonsterNames API

This Lambda function serves as the backend for the MonsterNames REST API, handling GET and POST requests for fantasy monster name generation and storage.

## Architecture

The Lambda is structured following best practices:

- **main.py** - Lambda handler entry point
- **config.py** - Configuration management (INI file parsing)
- **service.py** - Business logic for name operations
- **config.ini** - Endpoint to DynamoDB table mappings

## Features

- **GET requests**: Retrieve random monster names from DynamoDB
- **POST requests**: Insert new monster names into DynamoDB  
- **Automatic table creation**: Creates DynamoDB tables if they don't exist
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

### POST Request
```bash
curl -X POST https://monsternames.sudoblark.com/skeleton \
  -H "x-api-key: $API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"first_name": "Mortimer"}'
# Response: {"message": "Successfully inserted 'Mortimer' as valid 'first_name'."}
```

## Configuration Format

```ini
[/skeleton]
first_name_table = monsternames.skeleton.first_name
last_name_table = monsternames.skeleton.last_name

[/orc]
first_name_table = monsternames.orc.first_name
last_name_table = monsternames.orc.last_name
```

## Dependencies

- **boto3** - AWS SDK for DynamoDB operations
- **aws-lambda-powertools** - Structured event parsing and utilities
