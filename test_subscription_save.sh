#!/bin/bash

echo "🧪 Testing Core Data Subscription Save"
echo "======================================"
echo ""
echo "Monitoring console for save operations..."
echo ""

# Monitor the console log for subscription operations
xcrun simctl spawn EDEB2FDE-833E-47AE-9E63-65F2D415B93B log stream --level debug 2>/dev/null | grep -E "\[SubscriptionStore\]|\[PersistenceController\]|\[CoreDataReset\]" | while read -r line
do
    # Color code the output
    if [[ $line == *"✅"* ]] || [[ $line == *"saved successfully"* ]]; then
        echo -e "\033[32m$line\033[0m"  # Green for success
    elif [[ $line == *"❌"* ]] || [[ $line == *"Failed"* ]] || [[ $line == *"Error"* ]]; then
        echo -e "\033[31m$line\033[0m"  # Red for errors
    elif [[ $line == *"Adding subscription"* ]]; then
        echo -e "\033[33m$line\033[0m"  # Yellow for important events
    else
        echo "$line"
    fi
    
    # Check if save was successful
    if [[ $line == *"✅ Context saved successfully"* ]]; then
        echo ""
        echo "✨ SUCCESS! Subscription saved to Core Data!"
        echo ""
    fi
done