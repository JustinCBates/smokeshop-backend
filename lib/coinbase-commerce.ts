import "server-only";

const COINBASE_API_URL = "https://api.commerce.coinbase.com";

interface ChargeData {
  name: string;
  description: string;
  pricing_type: "fixed_price";
  local_price: {
    amount: string;
    currency: string;
  };
  metadata: {
    order_id: string;
    user_id: string;
    guest_email?: string;
    guest_phone?: string;
    guest_name?: string;
  };
  redirect_url?: string;
  cancel_url?: string;
}

interface CoinbaseCharge {
  id: string;
  code: string;
  hosted_url: string;
  pricing: {
    local: {
      amount: string;
      currency: string;
    };
  };
  created_at: string;
  expires_at: string;
}

export async function createCharge(data: ChargeData): Promise<CoinbaseCharge> {
  const apiKey = process.env.COINBASE_COMMERCE_API_KEY;
  
  if (!apiKey) {
    throw new Error("COINBASE_COMMERCE_API_KEY not configured");
  }

  const response = await fetch(`${COINBASE_API_URL}/charges`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "X-CC-Api-Key": apiKey,
      "X-CC-Version": "2018-03-22",
    },
    body: JSON.stringify(data),
  });

  if (!response.ok) {
    const error = await response.json();
    throw new Error(error.error?.message || "Failed to create charge");
  }

  const result = await response.json();
  return result.data;
}

export async function getCharge(chargeId: string): Promise<CoinbaseCharge> {
  const apiKey = process.env.COINBASE_COMMERCE_API_KEY;
  
  if (!apiKey) {
    throw new Error("COINBASE_COMMERCE_API_KEY not configured");
  }

  const response = await fetch(`${COINBASE_API_URL}/charges/${chargeId}`, {
    method: "GET",
    headers: {
      "X-CC-Api-Key": apiKey,
      "X-CC-Version": "2018-03-22",
    },
  });

  if (!response.ok) {
    const error = await response.json();
    throw new Error(error.error?.message || "Failed to get charge");
  }

  const result = await response.json();
  return result.data;
}
