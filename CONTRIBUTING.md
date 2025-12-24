# Contributing to rspec-clickhouse

First off, thanks for considering contributing to rspec-clickhouse! 🎉

## How Can I Contribute?

### Reporting Bugs

Before creating bug reports, please check existing issues to avoid duplicates. When you create a bug report, include as many details as possible:

- **Use a clear and descriptive title**
- **Describe the exact steps to reproduce the problem**
- **Provide specific examples** (code snippets, error messages)
- **Describe the behavior you observed** and what you expected
- **Include your environment details** (Ruby version, Rails version, ClickHouse version)

### Suggesting Enhancements

Enhancement suggestions are tracked as GitHub issues. When creating an enhancement suggestion:

- **Use a clear and descriptive title**
- **Provide a detailed description** of the suggested enhancement
- **Explain why this enhancement would be useful** to most users
- **Provide code examples** if applicable

### Pull Requests

1. **Fork the repo** and create your branch from `main`
2. **Make your changes** following the coding style below
3. **Add tests** for any new functionality
4. **Ensure all tests pass** (`bundle exec rspec`)
5. **Update documentation** (README, CHANGELOG) if needed
6. **Commit with clear messages** following the commit format below
7. **Submit a pull request**

## Development Setup

```bash
# Clone your fork
git clone https://github.com/YOUR_USERNAME/rspec-clickhouse.git
cd rspec-clickhouse

# Install dependencies
bundle install

# Run tests (requires ClickHouse running on localhost:8123)
bundle exec rspec
```

## Coding Style

- Follow standard Ruby style guidelines
- Use 2 spaces for indentation
- Keep lines under 120 characters
- Add comments for complex logic
- Use descriptive variable and method names

## Testing Guidelines

- Write unit tests for all new functionality
- Add integration tests when touching ClickHouse interaction
- Aim for high test coverage
- Tests should be fast and isolated

### Running Tests

```bash
# Unit tests only (no ClickHouse required)
bundle exec rspec spec/rspec/

# Integration tests (requires ClickHouse)
bundle exec rspec spec/integration/

# All tests
bundle exec rspec
```

## Commit Message Format

Use clear, descriptive commit messages:

```
Add feature X to support Y

- Detailed explanation of what changed
- Why it was needed
- Any breaking changes
```

For small fixes:
```
Fix typo in README
```

## Code Review Process

- All submissions require review before merging
- Maintainers will review your PR and may request changes
- Once approved, a maintainer will merge your PR

## Questions?

Feel free to open an issue with the "question" label!

## License

By contributing, you agree that your contributions will be licensed under the MIT License.
