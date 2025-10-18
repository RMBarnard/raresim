# Contributing to Raresim

Thank you for your interest in contributing to Raresim! We welcome contributions from the community to help improve this project.

## Code of Conduct

This project adheres to the Contributor Covenant [code of conduct](CODE_OF_CONDUCT.md). By participating, you are expected to uphold this code.

## How to Contribute

### Reporting Issues
- Check if the issue has already been reported in the [issue tracker](https://github.com/yourusername/raresim/issues)
- If not, create a new issue with a clear title and description
- Include steps to reproduce the issue, expected behavior, and actual behavior
- Specify the version of Raresim and Python you're using

### Feature Requests
- Open an issue with the "enhancement" label
- Describe the feature and its benefits
- Include any relevant use cases or examples

### Pull Requests
1. Fork the repository and create a new branch for your feature/fix
2. Ensure your code follows the project's style guide
3. Add tests for new functionality
4. Update documentation as needed
5. Run tests and ensure they pass
6. Submit a pull request with a clear description of the changes

## Development Setup

1. Fork and clone the repository
2. Set up a virtual environment:
   ```bash
   python -m venv .venv
   source .venv/bin/activate  # On Windows: .venv\Scripts\activate
   ```
3. Install development dependencies:
   ```bash
   pip install -r requirements-dev.txt
   ```
4. Install pre-commit hooks:
   ```bash
   pre-commit install
   ```

## Code Style

- Follow [PEP 8](https://www.python.org/dev/peps/pep-0008/) style guide
- Use type hints for all function signatures
- Keep lines under 88 characters (Black's default)
- Run `black .` to format your code
- Run `isort .` to sort imports
- Run `flake8` to check for style issues

## Testing

- Write tests for new functionality
- Run tests with `pytest`
- Ensure test coverage remains high
- Update tests when fixing bugs

## Documentation

- Update documentation when adding new features or changing behavior
- Keep docstrings up to date
- Follow Google style for docstrings

## Release Process

1. Update version in `pyproject.toml`
2. Update `CHANGELOG.md`
3. Create a release tag
4. Push changes to GitHub
5. Publish to PyPI
