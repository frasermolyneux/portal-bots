# B3 Player and Communication Events Reference

This document provides a comprehensive reference of B3 (BigBrotherBot) player lifecycle and communication events available for capture and storage. This information is intended to be used for extending the portal repository API to support these events.

## Event Object Structure

All B3 events follow a consistent object model:

### Standard Event Properties

- **`event.type`** - Integer event type ID
- **`event.client`** - Client object representing the player who triggered the event
- **`event.target`** - Client object representing the target/victim (for combat events)
- **`event.data`** - Event-specific data (can be string, list, tuple, or dict)

### Client Object Properties

When `event.client` or `event.target` is present, the client object contains:

- `client.id` - Database ID
- `client.guid` - Unique player identifier (GUID)
- `client.name` - Player name/nickname
- `client.ip` - IP address
- `client.team` - Current team
- `client.maxLevel` - Admin level
- `client.connections` - Number of connections
- Additional properties depending on game and plugins loaded

## Player Lifecycle Events

Player lifecycle events track the connection state and profile changes of players throughout their session on the server.

### Connection and Authentication Events

#### EVT_CLIENT_CONNECT
Player initially connects to the server.

**Available Data:**
- `event.client` - Client object of the connecting player

**Typical Usage:** Track when players first establish connection to the server, before authentication.

---

#### EVT_CLIENT_AUTH
Player successfully authenticates/is authorized.

**Available Data:**
- `event.client` - Client object of the authenticated player

**Typical Usage:** Track successful player authentication, confirming their identity.

---

#### EVT_CLIENT_JOIN
Player joins the game (post-authentication).

**Available Data:**
- `event.client` - Client object of the joining player

**Typical Usage:** Track when players actually join the game after connection and authentication.

---

#### EVT_CLIENT_DISCONNECT
Player disconnects from server.

**Available Data:**
- `event.client` - Client object of the disconnecting player

**Typical Usage:** Track when players leave the server, useful for session duration calculations.

---

### Player State Change Events

#### EVT_CLIENT_NAME_CHANGE
Player changes their name/nickname.

**Available Data:**
- `event.client` - Client object with the new name
- `event.data` - String containing the new name

**Typical Usage:** Track player identity changes, maintain name history for audit trails.

---

#### EVT_CLIENT_TEAM_CHANGE
Player changes team.

**Available Data:**
- `event.client` - Client object
- `event.data` - New team identifier

**Typical Usage:** Track team switches, useful for balancing analytics and team loyalty metrics.

---

#### EVT_CLIENT_UPDATE
Client state update (general purpose).

**Available Data:**
- `event.client` - Client object with updated state

**Typical Usage:** Track general client state changes not covered by specific events.

---

## Communication Events

Communication events capture all forms of player messages and chat interactions on the server.

### Chat Events

#### EVT_CLIENT_SAY
Public chat message to all players.

**Available Data:**
- `event.client` - Client object of the message sender
- `event.data` - String containing the message text

**Typical Usage:** Capture public chat for moderation, chat logs, and community interaction analysis.

**Example Message:** "Good game everyone!"

---

#### EVT_CLIENT_TEAM_SAY
Team-only chat message.

**Available Data:**
- `event.client` - Client object of the message sender
- `event.data` - String containing the message text

**Typical Usage:** Capture team-specific communication for team coordination analysis and moderation.

**Example Message:** "Incoming enemies from the north!"

---

#### EVT_CLIENT_SQUAD_SAY
Squad-only chat message (game-specific, e.g., Battlefield).

**Available Data:**
- `event.client` - Client object of the message sender
- `event.data` - String containing the message text

**Typical Usage:** Capture squad-level tactical communication in games that support squad mechanics.

**Note:** Only available in games with squad support (e.g., Battlefield series).

---

#### EVT_CLIENT_PRIVATE_SAY
Private message/whisper to specific player.

**Available Data:**
- `event.client` - Client object of the message sender
- `event.data` - String containing the message text
- Additional context may include target player information

**Typical Usage:** Capture private messages for moderation and harassment detection.

**Example Message:** "@PlayerName Can you help me with this objective?"

---

#### EVT_CLIENT_RADIO
Radio command issued (game-specific).

**Available Data:**
- `event.client` - Client object of the player issuing the radio command
- `event.data` - String or identifier for the radio command

**Typical Usage:** Track use of in-game radio commands, useful for communication pattern analysis.

**Note:** Game-specific feature, available in games with radio command systems.

**Example Commands:** "Need backup", "Roger that", "Hold position"

---

## Event Data Examples

### Example 1: Player Connection Flow

A typical player session involves the following lifecycle events in sequence:

1. **EVT_CLIENT_CONNECT** - Player establishes connection
   ```python
   event.client.guid = "abc123def456"
   event.client.name = "PlayerName"
   event.client.ip = "192.168.1.100"
   ```

2. **EVT_CLIENT_AUTH** - Player authenticates
   ```python
   event.client.guid = "abc123def456"  # Confirmed GUID
   event.client.name = "PlayerName"
   ```

3. **EVT_CLIENT_JOIN** - Player joins game
   ```python
   event.client.guid = "abc123def456"
   event.client.team = 1  # Assigned to team 1
   ```

4. **EVT_CLIENT_DISCONNECT** - Player leaves
   ```python
   event.client.guid = "abc123def456"
   event.client.connections = 42  # Total connection count
   ```

### Example 2: Communication Flow

Different types of communication events with sample data:

1. **Public Chat (EVT_CLIENT_SAY)**
   ```python
   event.client.guid = "abc123def456"
   event.client.name = "PlayerName"
   event.data = "Great shot!"
   ```

2. **Team Chat (EVT_CLIENT_TEAM_SAY)**
   ```python
   event.client.guid = "abc123def456"
   event.client.name = "PlayerName"
   event.client.team = 1
   event.data = "Cover me, going for the flag"
   ```

3. **Private Message (EVT_CLIENT_PRIVATE_SAY)**
   ```python
   event.client.guid = "abc123def456"
   event.client.name = "PlayerName"
   event.data = "Want to team up next round?"
   ```

### Example 3: Player State Changes

1. **Name Change (EVT_CLIENT_NAME_CHANGE)**
   ```python
   event.client.guid = "abc123def456"
   event.client.name = "NewPlayerName"  # Updated name
   event.data = "NewPlayerName"
   ```

2. **Team Change (EVT_CLIENT_TEAM_CHANGE)**
   ```python
   event.client.guid = "abc123def456"
   event.client.team = 2  # Switched to team 2
   event.data = 2  # New team ID
   ```

## Implementation Notes

### Event Availability

- **Connection Events** (CONNECT, AUTH, JOIN, DISCONNECT) are available in all B3 configurations
- **Chat Events** (SAY, TEAM_SAY) are available in all games
- **SQUAD_SAY** is only available in games with squad mechanics (e.g., Battlefield 3, BFBC2)
- **RADIO** events are game-specific and may not be available in all configurations

### Event Order

Player lifecycle events typically occur in this order:
1. `EVT_CLIENT_CONNECT` (initial connection)
2. `EVT_CLIENT_AUTH` (authentication)
3. `EVT_CLIENT_JOIN` (joins game)
4. Multiple gameplay and communication events
5. `EVT_CLIENT_DISCONNECT` (leaves server)

### Data Validation

When capturing these events, consider:

- **GUID** is the primary player identifier and should always be present
- **Player name** may change during a session (EVT_CLIENT_NAME_CHANGE)
- **IP address** may be null or masked for privacy compliance
- **Message text** should be stored as-is for audit purposes, apply filtering at display time
- **Team identifiers** are game-specific (may be integers, strings, or enums)

### Message Characteristics

Communication events typically have these characteristics:

- **Message length:** Generally 1-1000 characters (game-specific limits)
- **Encoding:** UTF-8 text
- **Special characters:** May include game-specific color codes or formatting
- **Frequency:** High volume - public chat can generate hundreds of events per hour on busy servers

## Current Portal Plugin Implementation

The existing portal plugin currently captures a subset of these events:

| Event | Currently Captured | Endpoint |
|-------|-------------------|----------|
| EVT_CLIENT_CONNECT | ✅ Yes | `/OnPlayerConnected` |
| EVT_CLIENT_AUTH | ❌ No | - |
| EVT_CLIENT_JOIN | ❌ No | - |
| EVT_CLIENT_DISCONNECT | ❌ No | - |
| EVT_CLIENT_NAME_CHANGE | ❌ No | - |
| EVT_CLIENT_TEAM_CHANGE | ❌ No | - |
| EVT_CLIENT_SAY | ✅ Yes | `/OnChatMessage` (type: 'All') |
| EVT_CLIENT_TEAM_SAY | ✅ Yes | `/OnChatMessage` (type: 'Team') |
| EVT_CLIENT_SQUAD_SAY | ❌ No | - |
| EVT_CLIENT_PRIVATE_SAY | ❌ No | - |
| EVT_CLIENT_RADIO | ❌ No | - |

### Current Data Format

**Player Connected:**
```python
{
    'eventGeneratedUtc': timestamp,
    'gameType': str,
    'serverId': str,
    'username': str,
    'guid': str,
    'ipAddress': str
}
```

**Chat Message:**
```python
{
    'eventGeneratedUtc': timestamp,
    'gameType': str,
    'serverId': str,
    'username': str,
    'guid': str,
    'message': str,
    'type': 'All' | 'Team'
}
```

## Expansion Opportunities

To provide comprehensive player and communication tracking, consider adding support for:

### High Priority
1. **EVT_CLIENT_DISCONNECT** - Essential for session tracking and analytics
2. **EVT_CLIENT_NAME_CHANGE** - Important for player identity audit trail
3. **EVT_CLIENT_PRIVATE_SAY** - Critical for moderation and harassment detection
4. **EVT_CLIENT_AUTH** and **EVT_CLIENT_JOIN** - Useful for detailed connection flow analysis

### Medium Priority
5. **EVT_CLIENT_TEAM_CHANGE** - Useful for team balance analytics
6. **EVT_CLIENT_SQUAD_SAY** - Valuable for Battlefield-specific deployments
7. **EVT_CLIENT_RADIO** - Interesting for communication pattern analysis in supported games

### Recommended Data Fields

For each captured event, consider storing:

**Common Fields (all events):**
- Event ID (UUID)
- Event Type (enum/string)
- Event Generated Timestamp (UTC)
- Server ID
- Game Type

**Player Identification:**
- Player GUID (primary identifier)
- Player Name (at time of event)
- Player IP Address (optional, privacy consideration)
- Player Team (for context)

**Event-Specific Data:**
- Message text (for communication events)
- Previous/new values (for state change events)
- Session duration (for disconnect events)
- Connection count (for disconnect events)

**Metadata:**
- Extensible metadata field (JSON/JSONB) for game-specific additional data
