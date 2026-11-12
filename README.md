<!-- PROJECT LOGO -->
<br />
<div align="center">

<h3 align="center">sudoblark.monsternames.api</h3>

  <p align="center">
    A serverless REST API that returns random fantasy monster names, and a worked example of data-driven Terraform.
  </p>
  <p align="center">
    <a href="https://monsternames.sudoblark.com">
      <img src="https://img.shields.io/badge/docs-Swagger%20UI-green?logo=swagger" alt="Swagger UI">
    </a>
    <a href="https://github.com/sudoblark/sudoblark.monsternames.api/blob/main/LICENSE.txt">
      <img src="https://img.shields.io/github/license/sudoblark/sudoblark.monsternames.api" alt="License">
    </a>
  </p>

</div>

# sudoblark.monsternames.api

A read-only REST API at [monsternames.sudoblark.com](https://monsternames.sudoblark.com), built on API Gateway, Lambda and DynamoDB, and deployed with the [data-driven Terraform](https://sudoblark.com/patterns/data-driven-terraform/) pattern.

## Using the API

Each monster has one `GET` route. It returns a random first name, a random last name if that monster has them, and both joined as `full_name`:

```bash
curl https://monsternames.sudoblark.com/skeleton
# {"first_name": "Reginald", "last_name": "Montgomery", "full_name": "Reginald Montgomery"}
```

| Route | Names themed on |
|-------|-----------------|
| `GET /goatmen` | Cute fluffy animals |
| `GET /goblin` | Washed out wrestlers and average blokes |
| `GET /ogre` | Caveman-like speech |
| `GET /orc` | A noun and a silly moniker |
| `GET /skeleton` | 18th century British gentlemen |
| `GET /troll` | A Scandinavian twist |

Any other route or method returns a 404. The [Swagger docs](https://monsternames.sudoblark.com) let you try each route, and the OpenAPI spec is at [`/openapi`](https://monsternames.sudoblark.com/openapi).

## How it's built

The repo follows the pattern's Variant B, so its infrastructure tier sits beside the data rather than in released modules:

- **Data tier**, [`modules/data/`](modules/data/): one file per primitive, such as [`lambdas.tf`](modules/data/lambdas.tf) or [`dynamodb_tables.tf`](modules/data/dynamodb_tables.tf), each opening with its contract of fields, constraints and an example. [`infrastructure.tf`](modules/data/infrastructure.tf) adds the defaults, full names and ARNs every entry needs.
- **Infrastructure tier**, [`modules/infrastructure/`](modules/infrastructure/): one generic module per primitive, each validating its inputs.
- **Instantiation tier**, [`infrastructure/aws-sudoblark-production/`](infrastructure/aws-sudoblark-production/): connects the two for the production account, with locked remote state.

The monsters are data too. Adding one takes an entry in [`modules/data/monsters.tf`](modules/data/monsters.tf) and its name lists in [`application/seed_data/`](application/seed_data/). Terraform then creates its tables and loads the names, adds its route to the Lambda, and gives it a path and a tag in the OpenAPI spec.

## Development

You need [tfenv](https://github.com/tfutils/tfenv), whose `tfenv install` in `infrastructure/aws-sudoblark-production/` installs the Terraform version its `.terraform-version` pins, and [uv](https://docs.astral.sh/uv/), which installs Python 3.13 and the dependencies `uv.lock` records:

```bash
uv sync
uv run pytest
uv run ruff check . && uv run ruff format --check .
```

Every module with a `tests/` folder has Terraform tests, which mock the AWS provider, so they run without credentials:

```bash
terraform -chdir=modules/data init && terraform -chdir=modules/data test
```

[pre-commit](https://pre-commit.com/) formats the Terraform and checks the YAML before each commit:

```bash
uv tool install pre-commit
pre-commit install
```

## CI/CD

Every pull request runs `terraform fmt`, `validate` and `test`, [checkov](https://www.checkov.io/), ruff, pytest, a plan against production and an [Infracost](https://www.infracost.io/) cost estimate. Applies are run by hand, from the Terraform Apply workflow on `main`.

## License

See [LICENSE.txt](LICENSE.txt) for details.
