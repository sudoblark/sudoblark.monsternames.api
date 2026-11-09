# Backend Lambda for MonsterNames API

This Lambda function serves as the backend for the read-only MonsterNames REST API, returning random fantasy monster names from the DynamoDB tables Terraform manages.

## Architecture

The Lambda is structured following best practices:

- **main.py** - Lambda handler entry point, mapping each route to its monster's tables
- **service.py** - Business logic for name operations

## Features

- **GET requests**: Retrieve random monster names from DynamoDB
- **Read-only**: Other methods get a 405, and names change only through `application/seed_data/`
- **Comprehensive logging**: Structured logging with configurable levels
- **Type safety**: Full type hints throughout codebase
- **Error handling**: Explicit exception handling with proper logging

## Environment Variables

| Variable | Required | Description | Default |
|----------|----------|-------------|---------|
| `MONSTER_TABLES` | Yes | JSON map of each monster to its name tables, generated from `modules/data/monsters.tf` | N/A |
| `LOG_LEVEL` | No | Logging level (DEBUG, INFO, WARNING, ERROR) | INFO |
| `DYNAMODB_ENDPOINT` | No | Custom DynamoDB endpoint (for local testing) | None |

## Building

```bash
./scripts/build-lambda.sh backend
```

This creates `lambda-packages/backend.zip` containing:
- Python code
- Dependencies from requirements.txt

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
- ✅ Clear separation of concerns (handler → service)

## API Usage

### GET Request
```bash
curl https://monsternames.sudoblark.com/skeleton
# Response: {"first_name": "Reginald", "last_name": "Montgomery", "full_name": "Reginald Montgomery"}
```

## Configuration Format

Terraform builds `MONSTER_TABLES` from `modules/data/monsters.tf`, so adding a monster there is all the Lambda needs. Each monster is served at `/<name>`, and `last_name` is `null` for monsters with first names only:

```json
{
  "goatmen": {
    "first_name": "aws-sudoblark-production-monsternames-api-goatmen-first-name",
    "last_name": null
  },
  "skeleton": {
    "first_name": "aws-sudoblark-production-monsternames-api-skeleton-first-name",
    "last_name": "aws-sudoblark-production-monsternames-api-skeleton-last-name"
  }
}
```

## Dependencies

- **boto3** - AWS SDK for DynamoDB operations
- **aws-lambda-powertools** - Structured event parsing and utilities
