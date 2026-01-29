# B3 Bot Event System Documentation

This document provides comprehensive documentation of the B3 (BigBrotherBot) event system used by the portal plugin to capture and send events to the main portal API for audit and player management.

## Table of Contents

- [Overview](#overview)
- [Current Portal Plugin Implementation](#current-portal-plugin-implementation)
- [Available Events](#available-events)
  - [Client Events](#client-events)
  - [Game Events](#game-events)
  - [Admin and Plugin Events](#admin-and-plugin-events)
  - [Game-Specific Events](#game-specific-events)
- [Event Data Properties](#event-data-properties)
- [Proposed Event Schemas](#proposed-event-schemas)
  - [Client Lifecycle Events Schema](#client-lifecycle-events-schema)
  - [Communication Events Schema](#communication-events-schema)
  - [Common Enumerations](#common-enumerations)
- [Key Findings](#key-findings)
  - [Server Broadcast Messages](#server-broadcast-messages)
  - [RCON Command Execution](#rcon-command-execution)
- [Event Usage Examples](#event-usage-examples)
- [Recommendations](#recommendations)

## Overview

The B3 bot system uses an event-driven architecture where plugins can register handlers for various game and player events. The `portal` plugin currently integrates with this system to capture specific events and forward them to the portal API.

## Current Portal Plugin Implementation

The portal plugin (`/src/plugins/portal/__init__.py`) currently captures the following events:

| Event | Endpoint | Purpose |
|-------|----------|---------|
| `EVT_CLIENT_SAY` | `/OnChatMessage` | Public chat messages |
| `EVT_CLIENT_TEAM_SAY` | `/OnChatMessage` | Team chat messages |
| `EVT_CLIENT_CONNECT` | `/OnPlayerConnected` | Player connections |
| `EVT_GAME_MAP_CHANGE` | `/OnMapChange` | Map changes |
| Plugin Startup | `/OnServerConnected` | Server connection |
| `like` command | `/OnMapVote` | Map vote (positive) |
| `dislike` command | `/OnMapVote` | Map vote (negative) |

### Current Event Data Properties

**OnChatMessage:**
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

**OnPlayerConnected:**
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

**OnMapChange:**
```python
{
    'eventGeneratedUtc': timestamp,
    'gameType': str,
    'serverId': str,
    'gameName': str,
    'mapName': str
}
```

## Available Events

Based on analysis of the B3 plugin ecosystem, the following events are available for registration:

### Client Events

#### Connection and Authentication
- **`EVT_CLIENT_CONNECT`** - Player initially connects to the server
  - Properties: `event.client`
  
- **`EVT_CLIENT_AUTH`** - Player successfully authenticates/is authorized
  - Properties: `event.client`
  
- **`EVT_CLIENT_JOIN`** - Player joins the game (post-authentication)
  - Properties: `event.client`
  
- **`EVT_CLIENT_DISCONNECT`** - Player disconnects from server
  - Properties: `event.client`

#### Communication Events
- **`EVT_CLIENT_SAY`** - Public chat message to all players
  - Properties: `event.client`, `event.data` (message text)
  
- **`EVT_CLIENT_TEAM_SAY`** - Team-only chat message
  - Properties: `event.client`, `event.data` (message text)
  
- **`EVT_CLIENT_SQUAD_SAY`** - Squad-only chat message (game-specific, e.g., Battlefield)
  - Properties: `event.client`, `event.data` (message text)
  
- **`EVT_CLIENT_PRIVATE_SAY`** - Private message/whisper to specific player
  - Properties: `event.client`, `event.data` (message text)
  
- **`EVT_CLIENT_RADIO`** - Radio command issued (game-specific)
  - Properties: `event.client`, `event.data` (radio command)

#### Combat Events
- **`EVT_CLIENT_KILL`** - Player kills an opponent
  - Properties: `event.client` (killer), `event.target` (victim), `event.data[0]` (damage), `event.data[1]` (weapon), `event.data[2]` (hit location)
  
- **`EVT_CLIENT_KILL_TEAM`** - Player kills a teammate (team kill)
  - Properties: Same as `EVT_CLIENT_KILL`
  
- **`EVT_CLIENT_DAMAGE`** - Player damages an opponent
  - Properties: `event.client` (attacker), `event.target` (victim), `event.data[0]` (damage points)
  
- **`EVT_CLIENT_DAMAGE_TEAM`** - Player damages a teammate
  - Properties: Same as `EVT_CLIENT_DAMAGE`
  
- **`EVT_CLIENT_DAMAGE_SELF`** - Self-inflicted damage
  - Properties: `event.client`, `event.data[0]` (damage points)
  
- **`EVT_CLIENT_SUICIDE`** - Player commits suicide
  - Properties: `event.client`
  
- **`EVT_CLIENT_GIB`** - Player gibs opponent (total destruction)
  - Properties: Similar to `EVT_CLIENT_KILL`
  
- **`EVT_CLIENT_GIB_TEAM`** - Player gibs teammate
  - Properties: Similar to `EVT_CLIENT_KILL`
  
- **`EVT_CLIENT_GIB_SELF`** - Player gibs self
  - Properties: `event.client`

#### Spawn and Movement
- **`EVT_CLIENT_SPAWN`** - Player spawns into game
  - Properties: `event.client`
  
- **`EVT_CLIENT_MOVE`** - Player movement detected (game-specific)
  - Properties: `event.client`
  
- **`EVT_CLIENT_STANDING`** - Player standing still (game-specific)
  - Properties: `event.client`

#### Player State Changes
- **`EVT_CLIENT_NAME_CHANGE`** - Player changes their name/nickname
  - Properties: `event.client`, `event.data` (new name)
  
- **`EVT_CLIENT_TEAM_CHANGE`** - Player changes team
  - Properties: `event.client`, `event.data` (new team)
  
- **`EVT_CLIENT_TEAM_CHANGE2`** - Alternative team change event (parser-specific)
  - Properties: `event.client`, `event.data`
  
- **`EVT_CLIENT_UPDATE`** - Client state update
  - Properties: `event.client`

#### Game Actions
- **`EVT_CLIENT_ACTION`** - General game action (flag capture, bomb plant, objective)
  - Properties: `event.client`, `event.data` (action type string)
  
- **`EVT_CLIENT_ITEM_PICKUP`** - Player picks up item
  - Properties: `event.client`, `event.data` (item)
  
- **`EVT_CLIENT_GEAR_CHANGE`** - Player changes gear/loadout
  - Properties: `event.client`, `event.data` (gear info)

#### Voting and Interaction
- **`EVT_CLIENT_CALLVOTE`** - Player initiates a vote
  - Properties: `event.client`, `event.data` (vote details)
  
- **`EVT_CLIENT_VOTE`** - Player casts a vote
  - Properties: `event.client`, `event.data` (vote choice)
  
- **`EVT_CLIENT_VOTE_START`** - Vote started (game-specific)
  - Properties: `event.client`, `event.data`

#### Jump Run Events (Urban Terror specific)
- **`EVT_CLIENT_JUMP_RUN_START`** - Jump run started
  - Properties: `event.client`
  
- **`EVT_CLIENT_JUMP_RUN_STOP`** - Jump run completed
  - Properties: `event.client`, `event.data` (time/score)
  
- **`EVT_CLIENT_JUMP_RUN_CANCEL`** - Jump run cancelled
  - Properties: `event.client`

#### Plugin-Generated Client Events
- **`EVT_CLIENT_SPAWNKILL`** - Player performed spawn kill
  - Properties: `event.client`, `event.target`
  
- **`EVT_CLIENT_SPAWNKILL_TEAM`** - Player performed spawn kill on teammate
  - Properties: `event.client`, `event.target`
  
- **`EVT_CLIENT_GEOLOCATION_SUCCESS`** - Geolocation lookup succeeded
  - Properties: `event.client`, `event.data` (location data)
  
- **`EVT_CLIENT_GEOLOCATION_FAILURE`** - Geolocation lookup failed
  - Properties: `event.client`, `event.data` (error)

#### Battlefield-Specific Events
- **`EVT_CLIENT_COMROSE`** - Comrose (communication rose) command
  - Properties: `event.client`, `event.data`
  
- **`EVT_CLIENT_POS_SAVE`** - Position saved
  - Properties: `event.client`
  
- **`EVT_CLIENT_POS_LOAD`** - Position loaded
  - Properties: `event.client`

#### Urban Terror Specific
- **`EVT_CLIENT_PUBLIC`** - Server public mode changed
  - Properties: `event.data` (public mode state)

### Game Events

- **`EVT_GAME_MAP_CHANGE`** - Map changes
  - Properties: `event.data` (dict with `'new'`: new map, `'old'`: old map)
  
- **`EVT_GAME_ROUND_START`** - Round starts
  - Properties: `event.data` (round info)
  
- **`EVT_GAME_ROUND_END`** - Round ends
  - Properties: `event.data` (round results)
  
- **`EVT_GAME_EXIT`** - Game/match ends
  - Properties: `event.data`
  
- **`EVT_GAME_WARMUP`** - Warmup period begins
  - Properties: `event.data`
  
- **`EVT_GAME_ROUND_PLAYER_SCORES`** - Player scores updated
  - Properties: `event.data` (score information)

### Admin and Plugin Events

- **`EVT_ADMIN_COMMAND`** - Admin command executed via B3
  - Properties: `event.client` (admin), `event.data[0]` (command object), `event.data[1]` (command parameters), `event.data[2]` (command results)
  
- **`EVT_PLUGIN_LOADED`** - Plugin loaded
  - Properties: `event.data` (plugin name)
  
- **`EVT_PLUGIN_UNLOADED`** - Plugin unloaded
  - Properties: `event.data` (plugin name)
  
- **`EVT_PLUGIN_ENABLED`** - Plugin enabled
  - Properties: `event.data` (plugin name)
  
- **`EVT_PLUGIN_DISABLED`** - Plugin disabled
  - Properties: `event.data` (plugin name)

- **`EVT_VOTE_PASSED`** - Vote passed
  - Properties: `event.data` (vote details)
  
- **`EVT_VOTE_FAILED`** - Vote failed
  - Properties: `event.data` (vote details)
  
- **`EVT_SERVER_VOTE_END`** - Server vote completed
  - Properties: `event.data` (vote results)

### Game-Specific Events

- **`EVT_ASSIST`** - Kill assist credited (Urban Terror 4.3)
  - Properties: `event.client`, `event.target`, `event.data`
  
- **`EVT_PUNKBUSTER_NEW_CONNECTION`** - PunkBuster new connection detected
  - Properties: `event.client`
  
- **`EVT_BAD_GUID`** - Bad GUID detected (anti-cheat)
  - Properties: `event.client`
  
- **`EVT_1337_PORT`** - Suspicious port usage detected
  - Properties: `event.client`
  
- **`EVT_FOLLOW_CONNECTED`** - Follow mode connection
  - Properties: `event.data`

- **`EVT_EXIT`** - Game exit signal
  - Properties: `event.data`
  
- **`EVT_STOP`** - Game stop signal
  - Properties: `event.data`

## Event Data Properties

All B3 events follow a consistent object model with the following standard properties:

### Standard Event Properties

- **`event.type`** - Integer event type ID
- **`event.client`** - Client object representing the player who triggered the event
- **`event.target`** - Client object representing the target/victim (for combat events)
- **`event.data`** - Event-specific data (can be string, list, tuple, or dict)

### Client Object Properties

When `event.client` or `event.target` is present, these client objects contain:

- `client.id` - Database ID
- `client.guid` - Unique player identifier (GUID)
- `client.name` - Player name/nickname
- `client.ip` - IP address
- `client.team` - Current team
- `client.maxLevel` - Admin level
- `client.connections` - Number of connections
- Additional properties depending on game and plugins loaded

## Proposed Event Schemas

This section defines the data schemas for client lifecycle and communication events that should be captured and stored by the portal API. These schemas are designed to be used by the repository layer for creating data structures for storage.

### Client Lifecycle Events Schema

Client lifecycle events track player connection states throughout their session on the server.

#### Base Lifecycle Event Schema

All lifecycle events share a common base schema:

```typescript
interface BaseLifecycleEvent {
  // Event metadata
  eventId: string;                    // Unique identifier for this event (UUID)
  eventType: LifecycleEventType;      // Type of lifecycle event (enum)
  eventGeneratedUtc: DateTime;        // UTC timestamp when event was generated
  
  // Server context
  serverId: string;                   // Unique server identifier
  gameType: string;                   // Game type (e.g., "cod4", "iourt43", "bf3")
  
  // Player information
  playerGuid: string;                 // Unique player identifier (GUID)
  playerName: string;                 // Player username/nickname at time of event
  playerIpAddress: string | null;     // Player IP address (nullable for privacy)
  
  // Additional context
  metadata: Record<string, any> | null; // Extensible metadata for game-specific data
}
```

#### Lifecycle Event Types (Enum)

```typescript
enum LifecycleEventType {
  CONNECT = "CONNECT",           // Initial connection to server (EVT_CLIENT_CONNECT)
  AUTH = "AUTH",                 // Player authenticated (EVT_CLIENT_AUTH)
  JOIN = "JOIN",                 // Player joined game (EVT_CLIENT_JOIN)
  DISCONNECT = "DISCONNECT",     // Player disconnected (EVT_CLIENT_DISCONNECT)
  NAME_CHANGE = "NAME_CHANGE",   // Player changed name (EVT_CLIENT_NAME_CHANGE)
  TEAM_CHANGE = "TEAM_CHANGE"    // Player changed team (EVT_CLIENT_TEAM_CHANGE)
}
```

#### Specific Lifecycle Event Schemas

**Player Connect Event:**
```typescript
interface PlayerConnectEvent extends BaseLifecycleEvent {
  eventType: LifecycleEventType.CONNECT;
  
  // Additional connect-specific fields
  connectionNumber: number | null;    // Number of times player has connected to this server
}
```

**Player Disconnect Event:**
```typescript
interface PlayerDisconnectEvent extends BaseLifecycleEvent {
  eventType: LifecycleEventType.DISCONNECT;
  
  // Additional disconnect-specific fields
  sessionDurationSeconds: number | null; // Duration of player's session in seconds
  disconnectReason: DisconnectReason | null; // Reason for disconnect (enum)
}
```

**Player Name Change Event:**
```typescript
interface PlayerNameChangeEvent extends BaseLifecycleEvent {
  eventType: LifecycleEventType.NAME_CHANGE;
  
  // Name change specific fields
  previousName: string;               // Player's previous name
  newName: string;                    // Player's new name (same as playerName)
}
```

**Player Team Change Event:**
```typescript
interface PlayerTeamChangeEvent extends BaseLifecycleEvent {
  eventType: LifecycleEventType.TEAM_CHANGE;
  
  // Team change specific fields
  previousTeam: TeamIdentifier | null; // Previous team
  newTeam: TeamIdentifier;             // New team
}
```

#### Supporting Enums for Lifecycle Events

**Disconnect Reason:**
```typescript
enum DisconnectReason {
  NORMAL = "NORMAL",                 // Normal disconnect
  KICKED = "KICKED",                 // Kicked by admin
  BANNED = "BANNED",                 // Banned from server
  TIMEOUT = "TIMEOUT",               // Connection timeout
  ERROR = "ERROR",                   // Connection error
  UNKNOWN = "UNKNOWN"                // Unknown reason
}
```

**Team Identifier:**
```typescript
enum TeamIdentifier {
  SPECTATOR = "SPECTATOR",           // Spectator/observer
  TEAM_1 = "TEAM_1",                 // Team 1 (e.g., Red, Allies, US)
  TEAM_2 = "TEAM_2",                 // Team 2 (e.g., Blue, Axis, RU)
  TEAM_3 = "TEAM_3",                 // Team 3 (game-specific)
  TEAM_4 = "TEAM_4",                 // Team 4 (game-specific)
  FREE_FOR_ALL = "FREE_FOR_ALL",     // No team (FFA mode)
  UNKNOWN = "UNKNOWN"                // Unknown team
}
```

### Communication Events Schema

Communication events capture all player messages and chat interactions on the server.

#### Base Communication Event Schema

All communication events share a common base schema:

```typescript
interface BaseCommunicationEvent {
  // Event metadata
  eventId: string;                    // Unique identifier for this event (UUID)
  eventType: "COMMUNICATION";         // Always "COMMUNICATION" for these events
  communicationType: CommunicationType; // Type of communication (enum)
  eventGeneratedUtc: DateTime;        // UTC timestamp when event was generated
  
  // Server context
  serverId: string;                   // Unique server identifier
  gameType: string;                   // Game type (e.g., "cod4", "iourt43", "bf3")
  
  // Sender information
  senderGuid: string;                 // Unique player identifier (GUID) of sender
  senderName: string;                 // Sender username/nickname
  senderTeam: TeamIdentifier | null;  // Sender's team at time of message
  
  // Message content
  message: string;                    // The actual message text
  messageLength: number;              // Length of message in characters
  
  // Additional context
  metadata: Record<string, any> | null; // Extensible metadata for game-specific data
}
```

#### Communication Types (Enum)

```typescript
enum CommunicationType {
  PUBLIC = "PUBLIC",                 // Public chat to all players (EVT_CLIENT_SAY)
  TEAM = "TEAM",                     // Team-only chat (EVT_CLIENT_TEAM_SAY)
  SQUAD = "SQUAD",                   // Squad-only chat (EVT_CLIENT_SQUAD_SAY)
  PRIVATE = "PRIVATE",               // Private message/whisper (EVT_CLIENT_PRIVATE_SAY)
  RADIO = "RADIO",                   // Radio command (EVT_CLIENT_RADIO)
  ADMIN = "ADMIN"                    // Admin command/chat
}
```

#### Specific Communication Event Schemas

**Public Chat Event:**
```typescript
interface PublicChatEvent extends BaseCommunicationEvent {
  communicationType: CommunicationType.PUBLIC;
  
  // No additional fields - message is visible to all players
}
```

**Team Chat Event:**
```typescript
interface TeamChatEvent extends BaseCommunicationEvent {
  communicationType: CommunicationType.TEAM;
  
  // Team chat specific fields
  targetTeam: TeamIdentifier;         // Team that can see this message
}
```

**Squad Chat Event:**
```typescript
interface SquadChatEvent extends BaseCommunicationEvent {
  communicationType: CommunicationType.SQUAD;
  
  // Squad chat specific fields
  squadId: string | null;             // Squad identifier (game-specific)
}
```

**Private Message Event:**
```typescript
interface PrivateMessageEvent extends BaseCommunicationEvent {
  communicationType: CommunicationType.PRIVATE;
  
  // Private message specific fields
  recipientGuid: string;              // Unique player identifier (GUID) of recipient
  recipientName: string;              // Recipient username/nickname
}
```

**Radio Command Event:**
```typescript
interface RadioCommandEvent extends BaseCommunicationEvent {
  communicationType: CommunicationType.RADIO;
  
  // Radio command specific fields
  radioCommand: string;               // Radio command identifier (game-specific)
  radioCommandCategory: string | null; // Command category (e.g., "orders", "responses")
}
```

#### Supporting Types for Communication Events

**Message Validation:**
```typescript
interface MessageValidation {
  isValid: boolean;                   // Whether message passes validation
  containsProfanity: boolean;         // Whether message contains filtered words
  isSpam: boolean;                    // Whether message is considered spam
  violationType: string | null;       // Type of violation if any
}
```

### Common Enumerations

These enumerations are used across multiple event types:

#### Game Types

Common game type identifiers:

```typescript
enum GameType {
  COD4 = "cod4",                     // Call of Duty 4
  IOURT41 = "iourt41",               // Urban Terror 4.1
  IOURT42 = "iourt42",               // Urban Terror 4.2
  IOURT43 = "iourt43",               // Urban Terror 4.3
  BF3 = "bf3",                       // Battlefield 3
  BFBC2 = "bfbc2",                   // Battlefield Bad Company 2
  MOH = "moh",                       // Medal of Honor
  COD7 = "cod7",                     // Call of Duty: Black Ops
  CUSTOM = "custom"                  // Custom/other game type
}
```

### Schema Implementation Examples

#### Example 1: Storing a Player Connect Event

```python
def onConnect(self, event):
    """Handle EVT_CLIENT_CONNECT"""
    
    lifecycle_event = {
        'eventId': str(uuid.uuid4()),
        'eventType': 'CONNECT',
        'eventGeneratedUtc': datetime.utcnow().isoformat(),
        'serverId': self._serverId,
        'gameType': self._gameType,
        'playerGuid': event.client.guid,
        'playerName': str(event.client.name),
        'playerIpAddress': event.client.ip,
        'connectionNumber': event.client.connections if hasattr(event.client, 'connections') else None,
        'metadata': None
    }
    
    self._postEvent(self._apimUrlBase + '/lifecycle-events', lifecycle_event)
```

#### Example 2: Storing a Communication Event

```python
def onSay(self, event):
    """Handle EVT_CLIENT_SAY (public chat)"""
    
    communication_event = {
        'eventId': str(uuid.uuid4()),
        'eventType': 'COMMUNICATION',
        'communicationType': 'PUBLIC',
        'eventGeneratedUtc': datetime.utcnow().isoformat(),
        'serverId': self._serverId,
        'gameType': self._gameType,
        'senderGuid': event.client.guid,
        'senderName': str(event.client.name),
        'senderTeam': self._mapTeamToIdentifier(event.client.team),
        'message': str(event.data),
        'messageLength': len(str(event.data)),
        'metadata': None
    }
    
    self._postEvent(self._apimUrlBase + '/communication-events', communication_event)
```

#### Example 3: Storing a Team Chat Event

```python
def onTeamSay(self, event):
    """Handle EVT_CLIENT_TEAM_SAY"""
    
    communication_event = {
        'eventId': str(uuid.uuid4()),
        'eventType': 'COMMUNICATION',
        'communicationType': 'TEAM',
        'eventGeneratedUtc': datetime.utcnow().isoformat(),
        'serverId': self._serverId,
        'gameType': self._gameType,
        'senderGuid': event.client.guid,
        'senderName': str(event.client.name),
        'senderTeam': self._mapTeamToIdentifier(event.client.team),
        'targetTeam': self._mapTeamToIdentifier(event.client.team),
        'message': str(event.data),
        'messageLength': len(str(event.data)),
        'metadata': None
    }
    
    self._postEvent(self._apimUrlBase + '/communication-events', communication_event)
```

#### Example 4: Storing a Player Disconnect Event

```python
def onDisconnect(self, event):
    """Handle EVT_CLIENT_DISCONNECT"""
    
    session_duration = None
    if hasattr(event.client, 'timeAdd') and event.client.timeAdd:
        session_duration = int(self.console.time() - event.client.timeAdd)
    
    lifecycle_event = {
        'eventId': str(uuid.uuid4()),
        'eventType': 'DISCONNECT',
        'eventGeneratedUtc': datetime.utcnow().isoformat(),
        'serverId': self._serverId,
        'gameType': self._gameType,
        'playerGuid': event.client.guid,
        'playerName': str(event.client.name),
        'playerIpAddress': event.client.ip,
        'sessionDurationSeconds': session_duration,
        'disconnectReason': 'NORMAL',  # Could be enhanced with actual reason detection
        'metadata': None
    }
    
    self._postEvent(self._apimUrlBase + '/lifecycle-events', lifecycle_event)
```

### Database Schema Recommendations

For the repository layer, consider these table structures:

#### Client Lifecycle Events Table

```sql
CREATE TABLE client_lifecycle_events (
    event_id UUID PRIMARY KEY,
    event_type VARCHAR(20) NOT NULL,  -- Enum: CONNECT, AUTH, JOIN, DISCONNECT, NAME_CHANGE, TEAM_CHANGE
    event_generated_utc TIMESTAMP NOT NULL,
    server_id VARCHAR(100) NOT NULL,
    game_type VARCHAR(20) NOT NULL,
    player_guid VARCHAR(100) NOT NULL,
    player_name VARCHAR(100) NOT NULL,
    player_ip_address VARCHAR(45),    -- IPv4 or IPv6
    connection_number INTEGER,
    session_duration_seconds INTEGER,
    disconnect_reason VARCHAR(20),    -- Enum: NORMAL, KICKED, BANNED, TIMEOUT, ERROR, UNKNOWN
    previous_name VARCHAR(100),
    new_name VARCHAR(100),
    previous_team VARCHAR(20),        -- Enum: SPECTATOR, TEAM_1, TEAM_2, etc.
    new_team VARCHAR(20),             -- Enum: SPECTATOR, TEAM_1, TEAM_2, etc.
    metadata JSONB,                   -- Flexible metadata storage
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    INDEX idx_player_guid (player_guid),
    INDEX idx_server_id (server_id),
    INDEX idx_event_type (event_type),
    INDEX idx_event_generated_utc (event_generated_utc)
);
```

#### Communication Events Table

```sql
CREATE TABLE communication_events (
    event_id UUID PRIMARY KEY,
    event_type VARCHAR(20) NOT NULL,  -- Always 'COMMUNICATION'
    communication_type VARCHAR(20) NOT NULL, -- Enum: PUBLIC, TEAM, SQUAD, PRIVATE, RADIO, ADMIN
    event_generated_utc TIMESTAMP NOT NULL,
    server_id VARCHAR(100) NOT NULL,
    game_type VARCHAR(20) NOT NULL,
    sender_guid VARCHAR(100) NOT NULL,
    sender_name VARCHAR(100) NOT NULL,
    sender_team VARCHAR(20),          -- Enum: SPECTATOR, TEAM_1, TEAM_2, etc.
    message TEXT NOT NULL,
    message_length INTEGER NOT NULL,
    target_team VARCHAR(20),          -- For team chat
    recipient_guid VARCHAR(100),      -- For private messages
    recipient_name VARCHAR(100),      -- For private messages
    squad_id VARCHAR(50),             -- For squad chat
    radio_command VARCHAR(50),        -- For radio commands
    radio_command_category VARCHAR(50), -- For radio commands
    metadata JSONB,                   -- Flexible metadata storage
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    INDEX idx_sender_guid (sender_guid),
    INDEX idx_server_id (server_id),
    INDEX idx_communication_type (communication_type),
    INDEX idx_event_generated_utc (event_generated_utc),
    FULLTEXT INDEX idx_message (message)  -- For message search
);
```

### Schema Validation Rules

1. **Required Fields:**
   - All `eventId`, `eventType`, `eventGeneratedUtc`, `serverId`, `gameType` are mandatory
   - Player identifiers (`playerGuid`/`senderGuid`) are mandatory
   - Message content is mandatory for communication events

2. **Data Type Constraints:**
   - `eventId` must be a valid UUID
   - `eventGeneratedUtc` must be ISO 8601 format with UTC timezone
   - `playerGuid`/`senderGuid` must be non-empty strings
   - Enum values must match predefined values exactly (case-sensitive)

3. **Length Constraints:**
   - `playerName`/`senderName`: 1-100 characters
   - `message`: 1-1000 characters (configurable)
   - `serverId`: 1-100 characters
   - `gameType`: 1-20 characters

4. **Optional Fields:**
   - `playerIpAddress` may be null for privacy compliance
   - `metadata` may be null or contain game-specific additional data
   - Context-specific fields (like `recipientGuid`, `squadId`) are nullable

## Key Findings

### Server Broadcast Messages

**Status: NOT DIRECTLY AVAILABLE**

After comprehensive analysis of the B3 event system and plugin ecosystem:

❌ **There is NO dedicated event for capturing server broadcast messages**

The B3 event system does not expose events for:
- Server-initiated broadcasts to all players
- Server messages sent to specific players
- System announcements
- Server notifications

**Workaround Options:**
1. Monitor admin plugin commands that trigger broadcasts (via `EVT_ADMIN_COMMAND`)
2. Implement custom parsing of game server logs to detect broadcast patterns
3. Hook into the console's `say()` and `saybig()` methods at a lower level (requires B3 core modifications)

**Example of indirect capture via EVT_ADMIN_COMMAND:**
The `EVT_ADMIN_COMMAND` event can capture when admins use commands like `!say` or `!announce` which result in server broadcasts:

```python
def onAdminCommand(self, event):
    command = event.data[0]  # Command object
    params = event.data[1]   # Command parameters
    results = event.data[2]  # Command results
    
    # Example: capturing !say command
    if command.command == 'say':
        # params contains the broadcast message
        # This is indirect - captures the command, not the actual broadcast
```

### RCON Command Execution

**Status: PARTIALLY AVAILABLE**

❌ **There is NO dedicated event for raw RCON commands**

✅ **Indirect tracking is possible via `EVT_ADMIN_COMMAND`**

**What's Available:**
- `EVT_ADMIN_COMMAND` captures admin commands executed through B3
- This includes commands that B3 translates to RCON commands
- Properties: command name, parameters, results, executing admin

**What's NOT Available:**
- Raw RCON commands sent directly to the game server (bypassing B3)
- RCON commands from external tools or scripts
- Low-level server console commands
- Direct server configuration changes via RCON

**Example Implementation:**

```python
def onAdminCommand(self, event):
    """
    Handle EVT_ADMIN_COMMAND to track RCON-like commands
    """
    admin_client = event.client
    command_obj = event.data[0]
    command_name = command_obj.command  # e.g., 'map', 'kick', 'ban'
    command_params = event.data[1]      # Command parameters
    command_results = event.data[2]     # Execution results
    
    # Send to portal API
    eventData = {
        'eventGeneratedUtc': datetime.utcnow().strftime('%Y-%m-%dT%H:%M:%S.%f%z'),
        'gameType': self._gameType,
        'serverId': self._serverId,
        'adminGuid': admin_client.guid,
        'adminUsername': admin_client.name,
        'command': command_name,
        'parameters': command_params,
        'results': command_results
    }
```

**Limitations:**
1. Only captures commands executed via B3's admin system
2. Does not capture direct RCON access from external sources
3. Does not capture server console commands
4. Command results may be empty or incomplete depending on the game

## Event Usage Examples

### Example 1: Tracking Player Kill/Death Ratio

```python
def onStartup(self):
    self.registerEvent('EVT_CLIENT_KILL', self.onKill)
    self.registerEvent('EVT_CLIENT_KILL_TEAM', self.onTeamKill)

def onKill(self, event):
    killer = event.client
    victim = event.target
    damage = int(event.data[0])
    weapon = event.data[1] if len(event.data) > 1 else None
    
    eventData = {
        'eventGeneratedUtc': datetime.utcnow().isoformat(),
        'killerId': killer.guid,
        'killerName': killer.name,
        'victimId': victim.guid,
        'victimName': victim.name,
        'damage': damage,
        'weapon': weapon
    }
    # Send to API...
```

### Example 2: Tracking All Communication

```python
def onStartup(self):
    self.registerEvent('EVT_CLIENT_SAY', self.onChat)
    self.registerEvent('EVT_CLIENT_TEAM_SAY', self.onChat)
    self.registerEvent('EVT_CLIENT_PRIVATE_SAY', self.onChat)
    if self.console.getEventID('EVT_CLIENT_SQUAD_SAY'):
        self.registerEvent('EVT_CLIENT_SQUAD_SAY', self.onChat)

def onChat(self, event):
    message_type = {
        'EVT_CLIENT_SAY': 'Public',
        'EVT_CLIENT_TEAM_SAY': 'Team',
        'EVT_CLIENT_PRIVATE_SAY': 'Private',
        'EVT_CLIENT_SQUAD_SAY': 'Squad'
    }.get(event.type, 'Unknown')
    
    eventData = {
        'eventGeneratedUtc': datetime.utcnow().isoformat(),
        'playerId': event.client.guid,
        'playerName': event.client.name,
        'message': str(event.data),
        'messageType': message_type
    }
    # Send to API...
```

### Example 3: Tracking Game Flow

```python
def onStartup(self):
    self.registerEvent('EVT_GAME_ROUND_START', self.onRoundStart)
    self.registerEvent('EVT_GAME_ROUND_END', self.onRoundEnd)
    self.registerEvent('EVT_GAME_MAP_CHANGE', self.onMapChange)

def onRoundStart(self, event):
    eventData = {
        'eventType': 'RoundStart',
        'eventGeneratedUtc': datetime.utcnow().isoformat(),
        'serverId': self._serverId,
        'mapName': self.console.game.mapName
    }
    # Send to API...

def onRoundEnd(self, event):
    eventData = {
        'eventType': 'RoundEnd',
        'eventGeneratedUtc': datetime.utcnow().isoformat(),
        'serverId': self._serverId,
        'mapName': self.console.game.mapName
    }
    # Send to API...
```

### Example 4: Admin Activity Tracking

```python
def onStartup(self):
    self.registerEvent('EVT_ADMIN_COMMAND', self.onAdminCommand)

def onAdminCommand(self, event):
    admin = event.client
    command = event.data[0]
    params = event.data[1] if len(event.data) > 1 else ''
    results = event.data[2] if len(event.data) > 2 else ''
    
    eventData = {
        'eventGeneratedUtc': datetime.utcnow().isoformat(),
        'serverId': self._serverId,
        'adminGuid': admin.guid,
        'adminName': admin.name,
        'adminLevel': admin.maxLevel,
        'command': command.command if hasattr(command, 'command') else str(command),
        'parameters': str(params),
        'results': str(results)
    }
    # Send to API...
```

## Recommendations

Based on the analysis, here are recommendations for expanding the portal plugin:

### High Priority - Readily Available

1. **Player Combat Events**
   - `EVT_CLIENT_KILL` - Track all kills with weapon and location data
   - `EVT_CLIENT_DAMAGE` - Track damage dealt
   - `EVT_CLIENT_KILL_TEAM` - Track team kills for moderation

2. **Admin Activity**
   - `EVT_ADMIN_COMMAND` - Complete audit trail of admin actions
   - Essential for accountability and moderation oversight

3. **Extended Player Events**
   - `EVT_CLIENT_DISCONNECT` - Track player session end
   - `EVT_CLIENT_NAME_CHANGE` - Track name changes for player identity
   - `EVT_CLIENT_TEAM_CHANGE` - Track team switches

4. **Game Flow Events**
   - `EVT_GAME_ROUND_START` / `EVT_GAME_ROUND_END` - Round-level analytics
   - `EVT_GAME_EXIT` - Match end events

### Medium Priority - Useful for Analytics

5. **Player Actions**
   - `EVT_CLIENT_ACTION` - Objective-based gameplay (flag caps, etc.)
   - `EVT_CLIENT_SPAWN` - Track spawn patterns
   - `EVT_ASSIST` - Track assists (if Urban Terror 4.3)

6. **Communication**
   - `EVT_CLIENT_PRIVATE_SAY` - Private messages for moderation
   - `EVT_CLIENT_SQUAD_SAY` - Squad chat (if applicable)

### Not Available - Requires Alternative Approach

7. **Server Broadcasts** ❌
   - No direct event available
   - Consider log file parsing or B3 core modifications

8. **Raw RCON Commands** ❌
   - No direct event available
   - Only admin commands via B3 are trackable
   - Consider external RCON monitoring tools

### Implementation Priority Matrix

| Feature | Availability | Priority | Implementation Effort |
|---------|-------------|----------|----------------------|
| Combat Events | ✅ Full | High | Low |
| Admin Commands | ✅ Partial | High | Low |
| Player Lifecycle | ✅ Full | High | Low |
| Game Flow | ✅ Full | Medium | Low |
| Player Actions | ✅ Full | Medium | Low |
| All Chat Types | ✅ Full | Medium | Low |
| Server Broadcasts | ❌ None | High | High (requires custom solution) |
| Raw RCON | ❌ None | Medium | High (requires external tool) |

## Conclusion

The B3 event system provides extensive coverage for player and game events, with rich data properties suitable for audit and player management. However, there are notable gaps:

- **Server broadcasts** cannot be captured directly through the event system
- **RCON commands** can only be partially tracked via `EVT_ADMIN_COMMAND` (B3-mediated commands only)

For comprehensive server communication monitoring, additional solutions beyond the B3 event system would be required, such as:
- Custom log file parsers
- RCON proxy/wrapper tools
- Game server plugins (if available for the specific game)
- B3 core modifications (not recommended)
