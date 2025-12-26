# Contributing to QuickCleaner

Thank you for your interest in contributing to QuickCleaner! This document provides guidelines and instructions for contributing.

## Code of Conduct

Please be respectful and constructive in all interactions. We're all here to build something great together.

## How to Contribute

### Reporting Bugs

1. **Check existing issues** to avoid duplicates
2. **Create a new issue** with:
   - Clear, descriptive title
   - Steps to reproduce
   - Expected vs actual behavior
   - macOS version and system info
   - Screenshots if applicable

### Suggesting Features

1. **Open a feature request issue**
2. Describe the feature and its use case
3. Explain why it would benefit users

### Pull Requests

1. **Fork** the repository
2. **Create a branch** from `main`:
   ```bash
   git checkout -b feature/your-feature-name
   ```
3. **Make your changes** following the code style below
4. **Test** your changes thoroughly
5. **Commit** with clear messages:
   ```bash
   git commit -m "feat: add new cache scanner for XYZ"
   ```
6. **Push** to your fork
7. **Open a Pull Request** with a clear description

## Development Setup

```bash
# Clone your fork
git clone https://github.com/YOUR_USERNAME/QuickCleaner.git
cd QuickCleaner

# Build and run
swift run

# Run tests
swift test
```

## Code Style

### Swift Guidelines

- Follow [Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/)
- Use meaningful variable and function names
- Add comments for complex logic
- Keep functions focused and small

### File Organization

```
QuickCleaner/
├── Models/      # Data structures
├── Views/       # SwiftUI views
├── ViewModels/  # Business logic
├── Services/    # File operations & scanning
└── Utilities/   # Helper functions
```

### Commit Messages

Use conventional commits:

- `feat:` New feature
- `fix:` Bug fix
- `docs:` Documentation only
- `style:` Formatting, no code change
- `refactor:` Code restructuring
- `test:` Adding tests
- `chore:` Maintenance tasks

## Testing

- Test on macOS 14.0+ (Sonoma)
- Verify all scanning features work
- Test file deletion with caution (use test directories)
- Check memory usage for large scans

## Questions?

Open an issue with the `question` label or start a discussion.

---

Thank you for contributing! 🎉
