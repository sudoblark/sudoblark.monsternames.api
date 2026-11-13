# Backend Lambda for MonsterNames API

This Lambda function serves as the backend for the read-only MonsterNames REST API, returning random fantasy monster names from the DynamoDB tables Terraform manages.

## Architecture

The Lambda is layered after Martin Fowler's [Patterns of Enterprise Application Architecture](https://martinfowler.com/eaaCatalog/), with dependencies running one way only. The layers every Lambda shares live in `application/lambda/common/`, which the build script bundles into the zip:

- **domain/** - `MonsterName`, a pure value object that owns the full name and imports nothing from the other layers
- **mappers/** - `MonsterNameMapper`, which turns a monster's name-table items into a `MonsterName`
- **repositories/** - `MonsterNameRepository`, which holds every monster's tables, pages through them and picks a random item from each
- **mixins/** - `MonsterNameRepoMixin`, which builds the repository from `MONSTER_TABLES` on first use, with a setter tests use to pass a double

**handler.py** holds only the edge: `MonsterNamesHandler`, composed with the mixin, maps each route to a monster, reads its name through the repository and shapes the response. Lambda calls the module-level `handler`.

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

This creates `lambda-packages/backend.zip`, which holds only the handler and `common/`. Its dependencies come from AWS, as [Dependencies](#dependencies) describes.

## Local Testing

Tests live in `tests/` at the repo root: `tests/common/` for the shared layers, and `tests/backend/` for the handler, which passes a repository double, plus wiring tests that run it end to end over DynamoDB mocked with moto. From the repo root, [uv](https://docs.astral.sh/uv/) installs Python 3.13 and the dependencies `uv.lock` records, then runs them:

```bash
uv sync
uv run pytest
```

## Code Quality

Follows [sudoblark.documentation Python standards](https://github.com/sudoblark/sudoblark.documentation):

- ✅ Explicit type hints on all functions and variables
- ✅ Google-style docstrings
- ✅ Comprehensive error handling
- ✅ Structured logging
- ✅ Clear separation of concerns (handler → repository → mapper → domain)
- ✅ Class-based handler, with its repository composed in through a mixin

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

- **boto3** - AWS SDK for DynamoDB operations, from the Lambda's Python runtime
- **aws-lambda-powertools** - Structured event parsing and utilities, from AWS's Powertools layer in `modules/data/lambdas.tf`

`pyproject.toml` pins the Powertools release that layer ships, so the tests run against the same code.
