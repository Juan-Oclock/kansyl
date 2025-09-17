# Currency Conversion Feature

## Overview
The app now supports automatic currency conversion when scanning receipts. If a receipt shows USD amounts but your app is set to PHP (Philippine Peso), it will automatically convert the amount using real-time exchange rates.

## How It Works

### 1. **Currency Detection**
When the AI scans a receipt, it detects:
- The amount (e.g., $45.00)
- The currency (e.g., USD)

### 2. **Automatic Conversion**
If the receipt currency differs from your app's currency setting:
- Fetches real-time exchange rates
- Converts the amount automatically
- Shows both original and converted amounts

### 3. **Exchange Rate Sources**
The app uses a two-tier system:
- **Primary**: Live exchange rates from exchangerate-api.com (updated hourly)
- **Fallback**: Built-in exchange rates if API is unavailable

## Features

### Real-Time Exchange Rates
- Updates every hour
- Supports 180+ currencies
- Caches rates to reduce API calls
- Falls back to hardcoded rates if API fails

### Current Fallback Rates (as of late 2024)
- 1 USD = 56.50 PHP
- 1 USD = 0.85 EUR
- 1 USD = 110 JPY
- And more...

### Transparent Display
When conversion occurs, you'll see:
1. **Converted amount**: ₱2,542.50/qtr
2. **Original amount**: (USD 45.00 converted)

## Example Scenario

### You scan a Mobbin Pro receipt:
- **Receipt shows**: USD $45.00 Quarterly
- **Your app currency**: Philippine Peso (₱)
- **Exchange rate**: 1 USD = 56.50 PHP

### What happens:
1. AI detects: $45 USD Quarterly
2. Converts: $45 × 56.50 = ₱2,542.50
3. Creates subscription: ₱2,542.50 Quarterly
4. Stores note: "Original: USD 45.00"

## User Interface

### Receipt Scan View
Shows both amounts:
```
Amount:    ₱2,542.50
Original:  USD 45.00
```

### Confirmation Dialog
```
₱2,542.50/quarter
(USD 45.00 converted)
```

### Subscription Notes
Preserves original amount:
```
"Added from receipt scan. Quarterly billing: 
PHP 2542.50 every 90 days. 
Original: USD 45.00. 
Receipt date: 11/17/24"
```

## Supported Currencies

Major currencies supported:
- **USD** - US Dollar
- **PHP** - Philippine Peso
- **EUR** - Euro
- **GBP** - British Pound
- **JPY** - Japanese Yen
- **SGD** - Singapore Dollar
- **AUD** - Australian Dollar
- **CAD** - Canadian Dollar
- Plus 30+ more currencies

## API Integration

### Exchange Rate API
- **Service**: exchangerate-api.com
- **Free Tier**: 1,500 requests/month
- **Update Frequency**: Hourly cache
- **No API Key Required**: Works out of the box

### To Add API Key (Optional)
For more requests, get a free API key:
1. Visit https://app.exchangerate-api.com/dashboard
2. Sign up for free account
3. Add key to the code in `CurrencyConversionService.swift`

## Error Handling

### If conversion fails:
1. Uses fallback exchange rates
2. If fallback unavailable, uses original amount
3. Shows warning in console logs
4. User can still proceed with original amount

## Debug Output

When converting currency, console shows:
```
💱 Currency conversion needed: USD → PHP
✅ Fetched fresh exchange rates for 168 currencies
💱 Currency conversion: 45.0 USD = 2542.50 PHP
   Exchange rates: 1 USD = 1.0 USD, 1 USD = 56.5 PHP
✅ Converted: 45.0 USD = 2542.50 PHP
```

## Benefits

1. **Accurate Tracking**: Subscriptions in your local currency
2. **Transparency**: Always shows original amount
3. **Real-Time Rates**: Uses current exchange rates
4. **Offline Support**: Works even without internet (fallback rates)
5. **Historical Record**: Preserves original currency in notes

## Testing

1. Set app currency to PHP (Settings → Currency)
2. Scan a receipt with USD amounts
3. Verify:
   - Conversion happens automatically
   - Both amounts displayed
   - Correct exchange rate applied
   - Original amount saved in notes

## Future Enhancements

1. Manual exchange rate override
2. Historical exchange rate tracking
3. Multiple currency support in one subscription
4. Exchange rate trend notifications
5. Currency conversion history view