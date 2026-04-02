import { afterEach, describe, expect, it } from "vitest";

import {
  getSiteUrl,
  isDevelopment,
  isProduction,
  validateEnv,
} from "./env";

const ORIGINAL_ENV = { ...process.env };

function setEnv(overrides: Record<string, string | undefined>) {
  process.env = {
    ...ORIGINAL_ENV,
    NODE_ENV: "test",
    ...overrides,
  };
}

afterEach(() => {
  process.env = { ...ORIGINAL_ENV };
});

describe("validateEnv", () => {
  it("reports missing required variables", () => {
    setEnv({
      NEXT_PUBLIC_SUPABASE_URL: undefined,
      NEXT_PUBLIC_SUPABASE_ANON_KEY: undefined,
      STRIPE_SECRET_KEY: undefined,
      NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY: undefined,
    });

    const result = validateEnv();

    expect(result.isValid).toBe(false);
    expect(result.missing).toEqual(
      expect.arrayContaining([
        expect.stringContaining("NEXT_PUBLIC_SUPABASE_URL"),
        expect.stringContaining("NEXT_PUBLIC_SUPABASE_ANON_KEY"),
        expect.stringContaining("STRIPE_SECRET_KEY"),
        expect.stringContaining("NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY"),
      ]),
    );
  });

  it("warns when Stripe keys use mixed modes", () => {
    setEnv({
      NEXT_PUBLIC_SUPABASE_URL: "https://example.supabase.co",
      NEXT_PUBLIC_SUPABASE_ANON_KEY: "anon-key",
      STRIPE_SECRET_KEY: "sk_test_123",
      NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY: "pk_live_456",
    });

    const result = validateEnv();

    expect(result.isValid).toBe(true);
    expect(result.warnings).toContain(
      "Stripe keys mode mismatch: secret and publishable keys should both be test or both be live",
    );
  });
});

describe("environment helpers", () => {
  it("uses the localhost fallback for development site URLs", () => {
    setEnv({ NODE_ENV: "development" });

    expect(isDevelopment()).toBe(true);
    expect(isProduction()).toBe(false);
    expect(getSiteUrl()).toBe("http://localhost:3000");
  });
});