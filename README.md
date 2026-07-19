# Custom Devcontainer Features & Templates

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)

A curated collection of reusable Developer Container (Devcontainer) features and templates. This repository helps developers and internal teams quickly spin up reproducible, isolated environments with specialized tools pre-configured, reducing environment setup time and configuration drift.

## Table of Contents

- [Features](#features)
- [Tech Stack](#tech-stack)
- [How it Works](#how-it-works)
- [Getting Started](#getting-started)
- [Usage](#usage)
- [Project Structure](#project-structure)
- [Roadmap](#roadmap)
- [Contributing](#contributing)
- [License](#license)

## Features

- Provides an ESP-IDF template for rapid IoT firmware development.
- Includes a feature for installing the `claude-code` CLI tool directly into your container.
- Includes an ephemeral `claude-code` variant that keeps config/credentials in memory only and wipes them when the container stops (ideal for shared machines).
- Includes a persistent `codex` feature that keeps OpenAI Codex config, authentication, and sessions across container rebuilds.
- Includes a feature for installing the `gemini-cli` for AI-assisted development.
- Extensible structure for adding more tools (like `rtk`) easily.

## Tech Stack

| Category | Technology |
| :--- | :--- |
| **Languages** | Shell Script, JSON |
| **Frameworks** | Devcontainers |
| **Tools** | Docker, VS Code (Dev Containers extension) |

## How it Works

This repository is divided into two main components: **Features** and **Templates**. 

1. **Features** (`/features`) are self-contained shell scripts and JSON metadata that install specific tools (like Claude or Gemini CLIs) into an existing dev container. 
2. **Templates** (`/templates`) are full baseline environments (like the ESP-IDF setup) that serve as a starting point for new projects. 

When referenced in a project's `devcontainer.json`, the devcontainer CLI downloads these assets and applies them during the container build process.

## Getting Started

### Prerequisites

- [Docker](https://www.docker.com/get-started) installed and running.
- [Visual Studio Code](https://code.visualstudio.com/) with the [Dev Containers extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers).

### Installation & Integration

To use a feature from this repository in your own project, add it to your `devcontainer.json`.

<!-- TODO: Update `<your-repo-url>` and `<refs>` to match your published GitHub repository -->

```json
{
  "image": "mcr.microsoft.com/devcontainers/base:ubuntu",
  "features": {
    "ghcr.io/<your-github-username>/<repo-name>/claude-code:1": {},
    "ghcr.io/<your-github-username>/<repo-name>/codex:1": {},
    "ghcr.io/<your-github-username>/<repo-name>/gemini-cli:1": {}
  }
}
```

### Running Locally (for development)

To test a feature locally:

```bash
# Install the devcontainers CLI
npm install -g @devcontainers/cli

# Run the devcontainer features test command
devcontainer features test -f features/src/claude-code -i mcr.microsoft.com/devcontainers/base:ubuntu
```

<!-- TODO: Update with any specific environment variables if your install scripts require API keys -->
*Note: Currently no specific environment variables are required for basic feature installation.*

## Usage

You can use the ESP-IDF template by opening a new VS Code window and selecting `Dev Containers: Add Dev Container Configuration Files`. If it is published, you can select it from the remote list.

For features, simply refer to them in any `devcontainer.json` as shown in the Installation section, rebuild your container, and the CLIs will be available in your terminal.

```bash
# Example usage inside the built container
claude --version
codex --version
gemini --help
```

## Project Structure

```text
.
├── features/
│   └── src/
│       ├── claude-code/            # Installs the Claude Code CLI tool (persistent config)
│       ├── claude-code-ephemeral/  # Claude Code with in-memory config wiped on stop
│       ├── codex/                  # Installs OpenAI Codex with persistent config and authentication
│       ├── gemini-cli/             # Installs the Gemini CLI tool
│       └── rtk/              # Installs the RTK dependencies
└── templates/
    └── esp-idf/              # Complete devcontainer template for ESP-IDF
```

## Roadmap

- [ ] Add testing matrix for features against different base images (Ubuntu, Alpine, Debian).
- [ ] Implement GitHub Actions CI/CD to automatically publish features to GHCR (GitHub Container Registry).
- [ ] Add more IoT templates (e.g., Zephyr RTOS).
- [ ] Add configuration options for the Gemini CLI and Claude Code features.

## Contributing

Contributions are always welcome! If you have an idea for a new feature or template, please open an issue first to discuss it, then feel free to submit a pull request. 

<!-- TODO: Add a link to the open issues page -->

## License

MIT
<!-- TODO: verify project license -->