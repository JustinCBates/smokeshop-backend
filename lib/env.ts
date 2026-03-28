/**
 * Environment variable validation utility
 * Validates that all required environment variables are present
 */

interface EnvValidationResult {
  isValid: boolean;
  missing: string[];
  warnings: string[];
}

/**
 * Required environment variables for the application
 */
const REQUIRED_ENV_VARS = {
  // Supabase - Required for database and auth
  NEXT_PUBLIC_SUPABASE_URL: 'Supabase project URL',
  NEXT_PUBLIC_SUPABASE_ANON_KEY: 'Supabase anonymous/public key',
  
  // Stripe - Required for payment processing
  STRIPE_SECRET_KEY: 'Stripe secret key (sk_test_... or sk_live_...)',
  NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY: 'Stripe publishable key (pk_test_... or pk_live_...)',
} as const;

/**
 * Optional environment variables with defaults
 */
const OPTIONAL_ENV_VARS = {
  NEXT_PUBLIC_SITE_URL: 'Site URL (defaults to http://localhost:3000)',
  AGE_VERIFICATION_PROVIDER: 'Age verification provider (defaults to dob-photo)',
  NEXT_PUBLIC_DEV_SUPABASE_REDIRECT_URL: 'Development redirect URL',
} as const;

/**
 * Validates all required environment variables
 * @param throwOnError - Whether to throw an error if validation fails
 * @returns Validation result with missing variables
 */
export function validateEnv(throwOnError = false): EnvValidationResult {
  const missing: string[] = [];
  const warnings: string[] = [];

  // Check required variables
  Object.entries(REQUIRED_ENV_VARS).forEach(([key, description]) => {
    const value = process.env[key];
    if (!value || value.trim() === '') {
      missing.push(`${key} - ${description}`);
    }
  });

  // Check optional variables and warn if not set
  Object.entries(OPTIONAL_ENV_VARS).forEach(([key, description]) => {
    const value = process.env[key];
    if (!value || value.trim() === '') {
      warnings.push(`${key} - ${description} (optional)`);
    }
  });

  // Validate Stripe key formats
  const stripeSecretKey = process.env.STRIPE_SECRET_KEY;
  if (stripeSecretKey && !stripeSecretKey.startsWith('sk_')) {
    warnings.push('STRIPE_SECRET_KEY should start with "sk_test_" or "sk_live_"');
  }

  const stripePublishableKey = process.env.NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY;
  if (stripePublishableKey && !stripePublishableKey.startsWith('pk_')) {
    warnings.push('NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY should start with "pk_test_" or "pk_live_"');
  }

  // Check if using test vs live mode consistently
  if (stripeSecretKey && stripePublishableKey) {
    const secretIsTest = stripeSecretKey.startsWith('sk_test_');
    const publishableIsTest = stripePublishableKey.startsWith('pk_test_');
    if (secretIsTest !== publishableIsTest) {
      warnings.push('Stripe keys mode mismatch: secret and publishable keys should both be test or both be live');
    }
  }

  const isValid = missing.length === 0;

  if (!isValid && throwOnError) {
    const errorMessage = [
      '❌ Missing required environment variables:',
      ...missing.map(m => `  - ${m}`),
      '',
      'Please add these to your .env file or deployment environment.',
      'See .env.example for reference.',
    ].join('\n');
    
    throw new Error(errorMessage);
  }

  return { isValid, missing, warnings };
}

/**
 * Logs environment validation results
 */
export function logEnvValidation(): void {
  const result = validateEnv(false);

  if (result.isValid) {
    console.log('✅ All required environment variables are set');
  } else {
    console.error('❌ Missing required environment variables:');
    result.missing.forEach(m => console.error(`  - ${m}`));
    console.error('\nPlease add these to your .env file or deployment environment.');
  }

  if (result.warnings.length > 0) {
    console.warn('\n⚠️  Environment warnings:');
    result.warnings.forEach(w => console.warn(`  - ${w}`));
  }
}

/**
 * Gets an environment variable with a fallback
 */
export function getEnvVar(key: string, fallback?: string): string {
  const value = process.env[key];
  if (!value && !fallback) {
    throw new Error(`Environment variable ${key} is required but not set`);
  }
  return value || fallback || '';
}

/**
 * Check if we're in production environment
 */
export function isProduction(): boolean {
  return process.env.NODE_ENV === 'production';
}

/**
 * Check if we're in development environment
 */
export function isDevelopment(): boolean {
  return process.env.NODE_ENV === 'development';
}

/**
 * Get the site URL with fallback
 */
export function getSiteUrl(): string {
  return getEnvVar(
    'NEXT_PUBLIC_SITE_URL',
    isDevelopment() ? 'http://localhost:3000' : ''
  );
}
