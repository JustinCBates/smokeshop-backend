# Cryptocurrency Payment Integration

This smokeshop accepts cryptocurrency payments through **Coinbase Commerce**.

## 🪙 Supported Cryptocurrencies

- **Bitcoin (BTC)** - The original cryptocurrency
- **Ethereum (ETH)** - Smart contract platform
- **USD Coin (USDC)** ⭐ - Stablecoin (1:1 with USD, no volatility)
- **Tether (USDT)** ⭐ - Stablecoin (1:1 with USD)
- **DAI** ⭐ - Decentralized stablecoin
- **Litecoin (LTC)** - Fast transaction cryptocurrency
- **Dogecoin (DOGE)** - Popular community coin
- **Bitcoin Cash (BCH)** - Bitcoin fork with larger blocks

⭐ = **Recommended for merchants** (no price volatility)

## 🚀 Current Setup: Coinbase Commerce

### Why Coinbase Commerce?

- ✅ Easy integration (currently implemented)
- ✅ Professional, trusted brand
- ✅ Multiple crypto support out of the box
- ✅ Optional auto-conversion to USD
- ✅ Good customer experience
- ⚠️ 1% transaction fee
- ⚠️ Requires Coinbase account

### Setup Instructions

1. **Create Account**
   - Go to [commerce.coinbase.com](https://commerce.coinbase.com)
   - Sign up with your Coinbase account
   - Complete business verification

2. **Get API Key**
   - Dashboard → Settings → API keys
   - Create an API key
   - Copy it to your `.env.local` file:
     ```
     COINBASE_COMMERCE_API_KEY=your_key_here
     ```

3. **Configure Webhooks** (Optional but recommended)
   - Settings → Webhook subscriptions
   - Add webhook URL: `https://yourdomain.com/api/webhooks/coinbase`
   - Select all event types
   - Copy shared secret to `.env.local`:
     ```
     COINBASE_COMMERCE_WEBHOOK_SECRET=your_secret_here
     ```

4. **Test**
   - Use Coinbase Commerce test mode
   - Create a small test charge
   - Complete payment with test crypto

## 💰 Future Option: BTCPay Server (Zero Fees)

For **zero fees** and **maximum control**, you can migrate to BTCPay Server later.

### Why BTCPay Server?

- ✅ **0% fees** - completely free forever
- ✅ Self-hosted - you control everything
- ✅ Complete privacy - no third party
- ✅ Bitcoin + Lightning Network support
- ✅ Optional altcoin support
- ⚠️ Requires server setup (Docker)
- ⚠️ More technical to manage

### Migration Path

When you're ready to save on fees:

1. Set up BTCPay Server on your own server or VPS
2. Install BTCPay Server Docker container
3. Create a store and API keys
4. Replace Coinbase Commerce integration with BTCPay
5. Keep both running during transition (optional)

**Savings Example:**
- $10,000/month in sales
- Coinbase Commerce: $100/month in fees (1%)
- BTCPay Server: $0/month in fees
- **Annual savings: $1,200+**

## 📊 Comparing Options

| Feature | Coinbase Commerce | BTCPay Server |
|---------|------------------|---------------|
| **Fees** | 1% | 0% |
| **Setup Time** | 15 minutes | 2-4 hours |
| **Hosting** | Cloud (handled) | Self-hosted |
| **Crypto Support** | 8+ coins | BTC + optional altcoins |
| **Privacy** | Moderate | Maximum |
| **Maintenance** | None | Regular updates |
| **Best For** | Quick start | Long-term cost savings |

## 🔄 How It Works

### Customer Experience

1. Customer adds items to cart
2. Proceeds to checkout
3. Clicks "Pay with Crypto"
4. Redirected to Coinbase Commerce hosted page
5. Chooses cryptocurrency (BTC, ETH, USDC, etc.)
6. Scans QR code or copies address
7. Sends payment from their wallet
8. Payment confirmed on blockchain
9. Order automatically updated to "confirmed"
10. Customer redirected to success page

### Merchant Experience

1. Receive payment notification
2. Funds appear in Coinbase Commerce account
3. Choose to:
   - Keep as cryptocurrency
   - Auto-convert to USD
   - Withdraw to bank account or crypto wallet

## 🛡️ Security Notes

- **API Keys**: Never commit `.env` files to git (already in `.gitignore`)
- **Webhooks**: Use webhook secret for signature verification
- **SSL/HTTPS**: Required for production (automatic with Hostinger)
- **Test Mode**: Always test with small amounts first

## 🆘 Troubleshooting

**"Failed to create charge" error:**
- Check API key is correct
- Verify API key has proper permissions
- Make sure you're using production API key in production

**Payment not confirming:**
- Check blockchain explorer for transaction status
- Small payments may take longer to confirm
- Check webhook is properly configured

**Need help?**
- Coinbase Commerce docs: [commerce.coinbase.com/docs](https://commerce.coinbase.com/docs)
- BTCPay Server docs: [docs.btcpayserver.org](https://docs.btcpayserver.org)

## 📝 Additional Resources

- [Coinbase Commerce API Reference](https://commerce.coinbase.com/docs/api/)
- [BTCPay Server Demo](https://mainnet.demo.btcpayserver.org/)
- [Lightning Network Info](https://lightning.network/)
- [Accepting Crypto for CBD](https://blog.coinbase.com/coinbase-commerce)

---

**Current Status:** ✅ Coinbase Commerce integrated and ready to use

**Next Steps:** 
1. Get your Coinbase Commerce API key
2. Add it to `.env.local`
3. Test with a small transaction
4. Consider BTCPay Server migration after 6-12 months
