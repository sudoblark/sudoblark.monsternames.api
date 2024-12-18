<!-- PROJECT LOGO -->
<br />
<div align="center">
  <a href="https://github.com/sudoblark/monsternames.api">
    <img src="docs/logo.png" alt="Logo" width="80" height="80">
  </a>

<h3 align="center">monsternames.api</h3>

  <p align="center">
    Containerised lambda, and configuration, for monsternames api.
  </p>
</div>


<!-- TABLE OF CONTENTS -->
<details>
  <summary>Table of Contents</summary>
  <ol>
    <li>
      <a href="#about-the-project">About The Project</a>
      <ul>
        <li><a href="#built-with">Built With</a></li>
      </ul>
    </li>
    <li><a href="#getting-started">Getting started</a></li>
    <li>
      <a href="#local-development">Local development</a>
      <ul>
        <li><a href="#pre-commit-hooks">Pre-commit hooks</a></li>
        <li><a href="#updating-the-configuration-file">Updating the configuration file</a></li>
        <li><a href="#updating-the-containerised-lambda">Updating the containerised lambda</a></li>
      </ul>
    </li>
    <li><a href="#environment-variables">Environment Variables</a></li>
    <li><a href="#automated-tests">Automated tests</a></li>
    <li><a href="#ci-cd-setup">CI/CD Setup</a></li>
    <li><a href="#contributing">Contributing</a></li>
    <li><a href="#license">License</a></li>
    <li><a href="#acknowledgments">Acknowledgments</a></li>
  </ol>
</details>



<!-- ABOUT THE PROJECT -->
## About The Project
This repo defines the monsternames.api in its entirety... both application
and Infrastructure code.

<p align="right">(<a href="#readme-top">back to top</a>)</p>



### Built With

* [DynamoDB](https://aws.amazon.com/dynamodb/)
* [ConfigParser](https://docs.python.org/3/library/configparser.html)
* [boto3](https://boto3.amazonaws.com/v1/documentation/api/latest/index.html)
* [mermaid](https://mermaid.js.org)
* [behave!](https://behave.readthedocs.io/en/latest/)
* [makefile](https://www.gnu.org/software/make/manual/make.html)

<p align="right">(<a href="#readme-top">back to top</a>)</p>



<!-- GETTING STARTED -->
## Getting Started

1. Decide if you need to update the configuration file, the lambda, or both.

```mermaid
---
title: Config vs lambda changes
---
flowchart

    startNode(((Start)))
    endNode(((End)))
    addingTablesQuestion{Are you adding endpoints and/or tables?}
    configChange[Change configuration file]
    lambdaQuestion{Do we need to change business logic for how we handle endpoint requests?}
    lambdaChange[Change lambda]

    startNode --> addingTablesQuestion
    addingTablesQuestion -- Yes --> configChange
    addingTablesQuestion -- No --> lambdaQuestion
    configChange --> lambdaQuestion
    lambdaQuestion -- Yes --> lambdaChange
    lambdaQuestion -- No --> endNode
    lambdaChange --> endNode
```

2. Make changes as appropriate as per the LOCAL DEVELOPMENT section.
3. Test your changes locally.
4. Submit a pull request.
5. Ensure automated checks pass, go through usual peer-review process.
6. Merge to main.
7. Once in main, a release on GitHub will automatically trigger a deployment to AWS.


<!-- LOCAL DEVELOPMENT -->
## Local Development
The below instructions are to assist local development of the containerised lambda and/or
the configuration file.

All instructions, unless otherwise stated, were only tested on MacOS.

### Pre-commit hooks
Pre-commit hooks are used to ensure appropriate formatting of code. To utilise:

1. Install pre-commit if you have not done so already:

```bash
pip3 install pre-commit
```

2. Install the hooks

```bash
pre-commit install
```

3. Do a pre-emptive run against all files:

```bash
pre-commit run --all-files
```

### Updating the configuration file
Simply add new section(s) to the `application/backend-lambda/config.ini` file to denote new endpoints.

Endpoints may define the following attributes:

| Attribute        | Purpose                                                                                                        |
|------------------|----------------------------------------------------------------------------------------------------------------|
| first_name_table | Defines DynamoDB table to lookup for first names. If omitted, these are excluded from full_name concatenation. |
| last_name_table  | Defines DynamoDB table to lookup for last names. If omitted, these are excluded from full_name concatenation.  |

### Updating the lambda

The lambdas main entrypoint is `handler` in `application\backend-lambda\backend_lambda\main.py`.
It also uses helper classes in `application\backend-lambda\backend_lambda\utilities.py` to generalise and
simplify as much as possible.

Simply update code as appropriate, then move on to manual then automated testing.

### Updating the API

The definition of the API is contained, in its entirety, in `application\open_api_definitions\monsternames.yaml`

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- Environment Variables -->
## Environment Variables
The following environment variables may be used to configure the container:

| Env var           | Permissible values                       | Description                                                                                                                         |
|-------------------|------------------------------------------|-------------------------------------------------------------------------------------------------------------------------------------|
| CONFIG_FILE       | A valid file path                        | Points the lambda to its configuration file as outlined in the "Updating the configuration file" section of this README.            |
| LOG_LEVEL         | NOTSET,DEBUG,INFO,WARNING,ERROR,CRITICAL | Log level for the logger inside the container to utilise, if blank will default to INFO.                                            |

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- Automated tests -->
## Automated tests

TODO

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- CI/CD -->
## CI/CD setup
CI is setup such that, on an open pull request:
- Ruff is used to lint all Python files
-  Tests - as outlined in the <a href="#automated-tests">Automated Tests</a> section - are run

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- CONTRIBUTING -->
## Contributing

If you have a suggestion that would make this better, please fork the repo and create a pull request. You can also simply open an issue with the tag "enhancement".
Don't forget to give the project a star! Thanks again!

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

<p align="right">(<a href="#top">back to top</a>)</p>

<!-- LICENSE -->
## License

Copyright (c) 2023, Sudoblark Ltd

All rights reserved.

This source code is licensed under the BSD 3 clause license found in the
LICENSE file in the root directory of this source tree.

<p align="right">(<a href="#readme-top">back to top</a>)</p>


<!-- ACKNOWLEDGMENTS -->
## Acknowledgments

* [Monster Creatures Fantasty](https://luizmelo.itch.io/monsters-creatures-fantasy) by luizmelo for the wonderful logo
