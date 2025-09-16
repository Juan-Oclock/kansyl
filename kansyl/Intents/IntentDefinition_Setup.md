# Kansyl Siri Shortcuts Intent Definition Setup

## Creating the Intent Definition File

1. In Xcode, go to File → New → File
2. Choose "SiriKit Intent Definition File" 
3. Name it "Kansyl.intentdefinition"
4. Add it to both the main app target and Intent Extension target

## Intent Definitions

### 1. AddTrialIntent

**Category:** Create
**Title:** Add Trial
**Description:** Add a new free trial to track

**Parameters:**
- `serviceName` (String)
  - Display Name: Service Name
  - Prompt: Which service trial would you like to add?
  - Siri can ask for value
  - Options: Netflix, Spotify, Disney+, Amazon Prime, Apple TV+, Hulu, Custom

**Response Properties:**
- `serviceName` (String) - The name of the service added
- `endDate` (Date) - When the trial ends
- `success` (Boolean) - Whether the trial was added successfully

**Suggested Invocation Phrase:** "Add [serviceName] trial"

### 2. CheckTrialsIntent

**Category:** Information
**Title:** Check Trials
**Description:** Check the status of your active trials

**Response Properties:**
- `message` (String) - Summary of trial status
- `activeCount` (Number) - Number of active trials
- `endingSoonCount` (Number) - Trials ending within 7 days

**Suggested Invocation Phrase:** "Check my trials"

### 3. QuickAddTrialIntent

**Category:** Create
**Title:** Quick Add Trial
**Description:** Quickly add a popular service trial

**Parameters:**
- `serviceType` (Enum)
  - Display Name: Service
  - Cases: Netflix, Spotify, Disney+, Amazon Prime, Apple TV+, Hulu
  - Siri can ask for value

**Response Properties:**
- `serviceName` (String) - The service that was added
- `message` (String) - Confirmation message

**Suggested Invocation Phrase:** "Quick add [service]"

## Intent Configuration

### Supported Combinations
1. AddTrialIntent - All parameters
2. CheckTrialsIntent - No parameters
3. QuickAddTrialIntent - Service type parameter

### Intent Eligibility
- All intents should be eligible for:
  - Suggestions
  - Donate Shortcuts
  - Voice Shortcuts

## App Integration Steps

1. **Add Intent Extension Target**
   - File → New → Target
   - Choose "Intents Extension"
   - Name: "KansylIntents"
   - Include Intent Definition file

2. **Configure Info.plist**
   ```xml
   <key>NSExtension</key>
   <dict>
       <key>NSExtensionAttributes</key>
       <dict>
           <key>IntentsSupported</key>
           <array>
               <string>AddTrialIntent</string>
               <string>CheckTrialsIntent</string>
               <string>QuickAddTrialIntent</string>
           </array>
       </dict>
       <key>NSExtensionPointIdentifier</key>
       <string>com.apple.intents-service</string>
       <key>NSExtensionPrincipalClass</key>
       <string>$(PRODUCT_MODULE_NAME).IntentHandler</string>
   </dict>
   ```

3. **Add Siri Capability**
   - Select main app target
   - Signing & Capabilities → + Capability
   - Add "Siri"

4. **Add App Groups** (for data sharing)
   - Add App Groups capability to both targets
   - Create group: "group.com.kansyl.shared"

5. **Update Core Data Stack**
   - Move persistent container to app group directory
   - Share Core Data between app and extension

## Usage Examples

### Siri Phrases:
- "Hey Siri, add Netflix trial to Kansyl"
- "Hey Siri, check my trials in Kansyl"
- "Hey Siri, quick add Spotify to Kansyl"
- "Hey Siri, what trials are ending soon in Kansyl"

### Shortcuts App Integration:
Users can create custom shortcuts combining:
- Add trial + Set reminder
- Check trials + Send notification
- Quick add + Open app

## Testing

1. **Simulator Testing**
   - Use Siri in simulator
   - Debug with print statements
   - Check Intent Extension logs

2. **Device Testing**
   - Test with actual Siri
   - Verify shortcuts appear in Settings
   - Test from Shortcuts app

3. **Common Issues**
   - Ensure app groups are configured
   - Check Intent Definition is in both targets
   - Verify Info.plist configuration
   - Check Siri permission is granted

## Code Snippets

### Donate Shortcut After Action
```swift
let intent = AddTrialIntent()
intent.serviceName = "Netflix"
intent.suggestedInvocationPhrase = "Add Netflix trial"

let interaction = INInteraction(intent: intent, response: nil)
interaction.donate { error in
    if let error = error {
        print("Failed to donate: \(error)")
    }
}
```

### Handle Intent in Extension
```swift
class IntentHandler: INExtension {
    override func handler(for intent: INIntent) -> Any {
        switch intent {
        case is AddTrialIntent:
            return AddTrialIntentHandler()
        default:
            fatalError("Unhandled intent")
        }
    }
}
```
