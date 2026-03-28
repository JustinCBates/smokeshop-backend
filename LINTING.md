# Linting and Type Checking Guide

This project uses ESLint for code linting and TypeScript for type checking.

## Setup

The project is configured with:

- **ESLint** - Code quality and style checking
- **TypeScript ESLint** - TypeScript-specific linting rules
- **Next.js ESLint Config** - Next.js best practices

## Running Linting

### Check for Issues

```bash
npm run lint
# or with pnpm
pnpm lint
```

### Auto-Fix Issues

```bash
npm run lint:fix
# or with pnpm
pnpm lint:fix
```

### Type Checking

```bash
npm run type-check
# or with pnpm
pnpm type-check
```

### Run Both Lint and Type Check

```bash
npm run check-all
# or with pnpm
pnpm check-all
```

## ESLint Configuration

The `.eslintrc.json` file includes:

### TypeScript Rules

- **@typescript-eslint/no-unused-vars**: Warns about unused variables (allows `_` prefix for intentionally unused)
- **@typescript-eslint/no-explicit-any**: Warns when using `any` type
- **@typescript-eslint/no-non-null-assertion**: Warns about `!` non-null assertions

### Code Quality Rules

- **no-console**: Warns about console.log (allows console.warn and console.error)
- **prefer-const**: Suggests using `const` when variables aren't reassigned
- **no-var**: Prevents use of `var` (use `let` or `const`)

### React Rules

- **react-hooks/rules-of-hooks**: Enforces Rules of Hooks
- **react-hooks/exhaustive-deps**: Checks effect dependencies

### Next.js Rules

- **@next/next/no-html-link-for-pages**: Use Next.js Link component for internal links
- **@next/next/no-img-element**: Use Next.js Image component instead of `<img>`

## Common Linting Issues and Fixes

### Unused Variables

**Issue:**

```typescript
const unusedVar = "hello"; // Warning: 'unusedVar' is assigned a value but never used
```

**Fix:**

```typescript
// Prefix with underscore if intentionally unused
const _unusedVar = "hello"; // No warning

// Or remove if truly not needed
```

### Using `any` Type

**Issue:**

```typescript
function handleData(data: any) {
  // Warning: Unexpected any
  return data;
}
```

**Fix:**

```typescript
// Use proper typing
function handleData(data: unknown) {
  return data;
}

// Or define an interface
interface Data {
  id: string;
  name: string;
}

function handleData(data: Data) {
  return data;
}
```

### Console Statements

**Issue:**

```typescript
console.log("Debug message"); // Warning: Unexpected console statement
```

**Fix:**

```typescript
// Remove before committing
// Or use allowed console methods
console.error("Error message"); // Allowed
console.warn("Warning message"); // Allowed

// For development debugging, use this pattern:
if (process.env.NODE_ENV === "development") {
  console.log("Debug message");
}
```

### Non-null Assertions

**Issue:**

```typescript
const value = process.env.API_KEY!; // Warning: Forbidden non-null assertion
```

**Fix:**

```typescript
// Check for null/undefined explicitly
const value = process.env.API_KEY;
if (!value) {
  throw new Error("API_KEY is required");
}
// Now TypeScript knows value is defined
```

### HTML Link in Next.js

**Issue:**

```typescript
<a href="/about">About</a> // Error: Use Link from next/link
```

**Fix:**

```typescript
import Link from 'next/link';

<Link href="/about">About</Link>
```

### Image Element

**Issue:**

```typescript
<img src="/logo.png" alt="Logo" /> // Warning: Use next/image
```

**Fix:**

```typescript
import Image from 'next/image';

<Image src="/logo.png" alt="Logo" width={200} height={100} />
```

## Ignoring Linting Errors

### Ignore Specific Line

```typescript
// eslint-disable-next-line @typescript-eslint/no-explicit-any
const data: any = fetchData();
```

### Ignore Specific Rule for File

```typescript
/* eslint-disable @typescript-eslint/no-explicit-any */
// File content
/* eslint-enable @typescript-eslint/no-explicit-any */
```

### Ignore Entire File

Add to `.eslintignore`:

```
path/to/file.ts
```

## Pre-commit Checks

To ensure code quality, you can set up pre-commit hooks using husky:

```bash
# Install husky and lint-staged
npm install --save-dev husky lint-staged

# Initialize husky
npx husky init

# Create pre-commit hook
echo "npm run lint-staged" > .husky/pre-commit
```

Add to `package.json`:

```json
{
  "lint-staged": {
    "*.{ts,tsx}": ["eslint --fix", "tsc --noEmit"]
  }
}
```

## IDE Integration

### VS Code

Install the ESLint extension:

1. Open Extensions (Ctrl+Shift+X)
2. Search for "ESLint"
3. Install official ESLint extension by Microsoft

Add to `.vscode/settings.json`:

```json
{
  "editor.codeActionsOnSave": {
    "source.fixAll.eslint": true
  },
  "eslint.validate": [
    "javascript",
    "javascriptreact",
    "typescript",
    "typescriptreact"
  ]
}
```

### Other IDEs

Most modern IDEs have ESLint plugins available:

- **WebStorm/IntelliJ**: Built-in ESLint support
- **Sublime Text**: Install SublimeLinter-eslint
- **Vim/Neovim**: Use ALE or coc-eslint

## CI/CD Integration

The GitHub Actions workflows already include linting:

**.github/workflows/pr-checks.yml**:

```yaml
- name: Run linter
  run: pnpm lint

- name: Check TypeScript
  run: npx tsc --noEmit
```

## Customizing Rules

To modify ESLint rules, edit `.eslintrc.json`:

```json
{
  "rules": {
    // Turn off a rule
    "no-console": "off",

    // Change severity: "off", "warn", or "error"
    "@typescript-eslint/no-explicit-any": "error",

    // Add options
    "@typescript-eslint/no-unused-vars": [
      "error",
      { "argsIgnorePattern": "^_" }
    ]
  }
}
```

## Troubleshooting

### ESLint Not Running

```bash
# Reinstall dependencies
rm -rf node_modules
npm install

# Check ESLint is installed
npx eslint --version
```

### Type Errors After Linting

```bash
# Run type check separately
npm run type-check

# Clear Next.js cache
rm -rf .next
npm run build
```

### Slow Linting

Add files/folders to `.eslintignore`:

```
node_modules/
.next/
out/
build/
```

## Best Practices

1. **Run lint before committing**: `npm run check-all`
2. **Fix warnings early**: Don't let them accumulate
3. **Use proper types**: Avoid `any` when possible
4. **Remove console.log**: Use proper logging in production
5. **Follow Next.js conventions**: Use Link and Image components

## Resources

- [ESLint Documentation](https://eslint.org/docs/latest/)
- [TypeScript ESLint](https://typescript-eslint.io/)
- [Next.js ESLint](https://nextjs.org/docs/app/building-your-application/configuring/eslint)
- [React Hooks Rules](https://react.dev/reference/rules/rules-of-hooks)

---

**Note**: When you first run linting on an existing codebase, you may see many warnings. Focus on fixing errors first, then gradually address warnings over time.
