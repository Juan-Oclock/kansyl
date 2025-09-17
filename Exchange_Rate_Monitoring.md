# Exchange Rate Monitoring & Updates

## Overview
The app now tracks exchange rates over time and automatically updates subscription amounts when rates change significantly, ensuring your budget tracking remains accurate even as currencies fluctuate.

## How It Works

### 1. **Initial Conversion**
When you scan a receipt in foreign currency:
- Converts using current exchange rate
- **Stores the original amount** (e.g., USD $45)
- **Records the exchange rate used** (e.g., 1 USD = 56.50 PHP)
- **Tracks conversion date**

### 2. **Automatic Monitoring**
The app monitors exchange rates:
- **Checks daily** for rate changes
- **5% threshold**: Only updates if rate changes by 5% or more
- **Preserves history**: Adds notes about each rate update

### 3. **Smart Updates**
When rates change significantly:
- **Recalculates amounts** using new rate
- **Updates subscription display**
- **Sends notification** about the change
- **Logs changes** in subscription notes

## Example Scenario

### Day 1: You Create Subscription
- **Receipt**: USD $45 Quarterly
- **Exchange rate**: 1 USD = 56.50 PHP
- **Created as**: ₱2,542.50 Quarterly

### Day 30: Exchange Rate Changes
- **New rate**: 1 USD = 59.00 PHP (+4.4%)
- **No update**: Change below 5% threshold

### Day 60: Significant Change
- **New rate**: 1 USD = 60.50 PHP (+7.1%)
- **Automatic update**: 
  - New amount: ₱2,722.50 Quarterly
  - Notification sent
  - Note added to subscription

## Features

### Exchange Rate Card
Shows in subscription details:
```
Exchange Rate                    ↑ 7.1%
─────────────────────────────────────────
Current Amount:           ₱2,722.50
Original Amount:          USD 45.00

Exchange Rate:            1 USD = 60.50 PHP
Last Updated:             12/15/24

⚠️ Exchange rate has changed significantly
[Update to Current Rate]
```

### Update History
Stored in subscription notes:
```
[Rate Update 12/15/24]: Exchange rate increased by 7.1%. 
New rate: 1 USD = 60.50 PHP. 
Amount changed from PHP 2542.50 to 2722.50.
```

### Notifications
When rates change significantly:
```
"Exchange Rates Updated"
"2 subscription amounts were updated due to 
exchange rate changes."
```

## Smart Features

### 1. **Threshold-Based Updates**
- Only updates when change ≥ 5%
- Prevents constant minor adjustments
- Reduces notification spam

### 2. **Daily Check Limit**
- Checks once per day per subscription
- Conserves API calls
- Balances accuracy with efficiency

### 3. **Manual Update Option**
- "Update to Current Rate" button
- Available when significant change detected
- Immediate refresh with latest rates

### 4. **Historical Tracking**
- All rate changes logged in notes
- Shows percentage changes
- Tracks amount differences

## Data Stored

For each foreign currency subscription:
- `originalCurrency`: USD
- `originalAmount`: 45.00
- `exchangeRate`: 56.50
- `lastRateUpdate`: Date of last check
- `billingAmount`: Current converted amount
- Update history in notes

## Benefits

### 1. **Accurate Budgeting**
- Reflects real currency values
- Updates automatically
- Shows true cost changes

### 2. **Transparency**
- Always see original amount
- Track rate changes over time
- Understand cost fluctuations

### 3. **Control**
- 5% threshold prevents noise
- Manual update available
- Notification settings

### 4. **Historical Record**
- Complete audit trail
- Rate change history
- Amount change tracking

## User Interface Updates

### Subscription List
- Shows current converted amount
- Updates automatically when rates change

### Subscription Details
- Exchange Rate Card shows current vs original
- Warning for significant changes
- Update button when needed

### Notifications
- Alert when amounts update
- Summary of changes
- Tap to view details

## Testing the Feature

1. **Create foreign subscription**:
   - Scan USD receipt
   - Converts to PHP
   - Stores exchange rate

2. **Simulate rate change**:
   - Wait 24 hours (or modify date)
   - Rate changes by 5%+
   - Automatic update occurs

3. **Check updates**:
   - View subscription notes
   - See new amount
   - Check notification

## Technical Details

### Update Frequency
- **Check interval**: Every 24 hours
- **Update threshold**: 5% change
- **API cache**: 1 hour

### Rate Sources
- **Primary**: Live API rates
- **Fallback**: Hardcoded rates
- **Cache**: Reduces API calls

### Performance
- **Background updates**: Non-blocking
- **Batch processing**: All subscriptions at once
- **Efficient queries**: Only foreign currency subs

## Future Enhancements

1. **Customizable threshold** (3%, 5%, 10%)
2. **Rate change predictions**
3. **Currency trend charts**
4. **Multi-currency budgets**
5. **Rate lock option** (fix rate for X months)
6. **Exchange rate alerts**

## Important Notes

⚠️ **Core Data Changes**: Delete and reinstall app for new fields to work

⚠️ **Rate Limits**: Free API tier has request limits

⚠️ **Historical Data**: Rate updates start from creation date

## Summary

The app now handles exchange rate fluctuations intelligently:
- **Tracks** original amounts and rates
- **Monitors** for significant changes
- **Updates** automatically when needed
- **Notifies** you of changes
- **Preserves** complete history

Your subscriptions stay accurate even as currencies fluctuate!