# B3 Events Reference for Portal Repository API

This document provides a focused reference of B3 (BigBrotherBot) events selected for capture and storage by the portal repository API. These events support player lifecycle tracking, communication monitoring, game state management, and administration features.

## Event Categories

This document covers 16 specific event types organized into four categories:

1. **Player Lifecycle Events** (5 events) - Track player connections and profile changes
2. **Communication Events** (5 events) - Capture player chat and communication
3. **Custom Plugin Events** (2 events) - Custom map voting functionality
4. **Server and Game Events** (7 events) - Server state and game flow tracking

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
- `client.team` - Current team identifier
- `client.maxLevel` - Admin level
- `client.connections` - Number of connections to this server
- Additional properties depending on game and plugins loaded

- Additional properties depending on game and plugins loaded

---

## Player Lifecycle Events

These events track player connections, authentication, and profile changes throughout their session on the server.

### EVT_CLIENT_CONNECT

**Event Type:** Player Lifecycle  
**Description:** Triggered when a player initially establishes connection to the server, before authentication.

**Event Data Structure:**
```python
{
    'event.type': int,           # Event type ID
    'event.client': Client       # Client object of connecting player
}
```

**Available Client Properties:**
- `client.guid` - Unique player identifier (GUID)
- `client.name` - Player name/nickname
- `client.ip` - IP address
- `client.connections` - Connection count to this server

**Typical Usage:** Track initial connection attempts, monitor connection patterns, detect connection issues.

**Example:**
```python
def onConnect(self, event):
    eventData = {
        'eventGeneratedUtc': datetime.utcnow().isoformat(),
        'eventType': 'EVT_CLIENT_CONNECT',
        'gameType': self._gameType,
        'serverId': self._serverId,
        'playerGuid': event.client.guid,
        'playerName': str(event.client.name),
        'playerIpAddress': event.client.ip,
        'connectionNumber': event.client.connections
    }
```

---

### EVT_CLIENT_AUTH

**Event Type:** Player Lifecycle  
**Description:** Triggered when a player successfully authenticates and their identity is confirmed by the server.

**Event Data Structure:**
```python
{
    'event.type': int,           # Event type ID
    'event.client': Client       # Client object of authenticated player
}
```

**Available Client Properties:**
- `client.guid` - Confirmed unique player identifier (GUID)
- `client.name` - Authenticated player name
- `client.maxLevel` - Player's admin level
- `client.id` - Database ID (if player is registered)

**Typical Usage:** Confirm player identity, track successful authentications, link to player profiles.

**Example:**
```python
def onAuth(self, event):
    eventData = {
        'eventGeneratedUtc': datetime.utcnow().isoformat(),
        'eventType': 'EVT_CLIENT_AUTH',
        'gameType': self._gameType,
        'serverId': self._serverId,
        'playerGuid': event.client.guid,
        'playerName': str(event.client.name),
        'playerDbId': event.client.id,
        'playerLevel': event.client.maxLevel
    }
```

---

### EVT_CLIENT_JOIN

**Event Type:** Player Lifecycle  
**Description:** Triggered when a player joins the game after successful connection and authentication.

**Event Data Structure:**
```python
{
    'event.type': int,           # Event type ID
    'event.client': Client       # Client object of joining player
}
```

**Available Client Properties:**
- `client.guid` - Unique player identifier (GUID)
- `client.name` - Player name
- `client.team` - Initial team assignment
- `client.maxLevel` - Admin level

**Typical Usage:** Track active player joins, record session start time, initialize player state.

**Example:**
```python
def onJoin(self, event):
    eventData = {
        'eventGeneratedUtc': datetime.utcnow().isoformat(),
        'eventType': 'EVT_CLIENT_JOIN',
        'gameType': self._gameType,
        'serverId': self._serverId,
        'playerGuid': event.client.guid,
        'playerName': str(event.client.name),
        'playerTeam': event.client.team
    }
```

---

### EVT_CLIENT_DISCONNECT

**Event Type:** Player Lifecycle  
**Description:** Triggered when a player disconnects from the server.

**Event Data Structure:**
```python
{
    'event.type': int,           # Event type ID
    'event.client': Client       # Client object of disconnecting player
}
```

**Available Client Properties:**
- `client.guid` - Unique player identifier (GUID)
- `client.name` - Player name
- `client.timeAdd` - Connection timestamp (for session duration calculation)
- `client.connections` - Total connection count

**Typical Usage:** Track disconnections, calculate session duration, update player statistics.

**Example:**
```python
def onDisconnect(self, event):
    session_duration = None
    if hasattr(event.client, 'timeAdd') and event.client.timeAdd:
        session_duration = int(self.console.time() - event.client.timeAdd)
    
    eventData = {
        'eventGeneratedUtc': datetime.utcnow().isoformat(),
        'eventType': 'EVT_CLIENT_DISCONNECT',
        'gameType': self._gameType,
        'serverId': self._serverId,
        'playerGuid': event.client.guid,
        'playerName': str(event.client.name),
        'sessionDurationSeconds': session_duration
    }
```

---

### EVT_CLIENT_NAME_CHANGE

**Event Type:** Player Lifecycle  
**Description:** Triggered when a player changes their name/nickname during a session.

**Event Data Structure:**
```python
{
    'event.type': int,           # Event type ID
    'event.client': Client,      # Client object with new name
    'event.data': str            # New player name
}
```

**Available Properties:**
- `client.guid` - Unique player identifier (GUID)
- `client.name` - New player name (current)
- `event.data` - New name (same as client.name)

**Typical Usage:** Track identity changes, maintain name history, detect suspicious name changes.

**Example:**
```python
def onNameChange(self, event):
    eventData = {
        'eventGeneratedUtc': datetime.utcnow().isoformat(),
        'eventType': 'EVT_CLIENT_NAME_CHANGE',
        'gameType': self._gameType,
        'serverId': self._serverId,
        'playerGuid': event.client.guid,
        'previousName': 'previous_name_if_available',  # Store previous name separately
        'newName': str(event.data)
    }
```

---

## Communication Events

These events capture all forms of player messages and chat interactions on the server.

### EVT_CLIENT_SAY

**Event Type:** Communication  
**Description:** Public chat message visible to all players on the server.

**Event Data Structure:**
```python
{
    'event.type': int,           # Event type ID
    'event.client': Client,      # Client object of message sender
    'event.data': str            # Message text
}
```

**Available Properties:**
- `client.guid` - Unique player identifier (GUID)
- `client.name` - Player name
- `client.team` - Player's team
- `event.data` - Message text content

**Typical Usage:** Monitor public chat, detect inappropriate content, create chat logs, analyze communication patterns.

**Example:**
```python
def onSay(self, event):
    eventData = {
        'eventGeneratedUtc': datetime.utcnow().isoformat(),
        'eventType': 'EVT_CLIENT_SAY',
        'communicationType': 'PUBLIC',
        'gameType': self._gameType,
        'serverId': self._serverId,
        'senderGuid': event.client.guid,
        'senderName': str(event.client.name),
        'senderTeam': event.client.team,
        'message': str(event.data),
        'messageLength': len(str(event.data))
    }
```

---

### EVT_CLIENT_TEAM_SAY

**Event Type:** Communication  
**Description:** Team-only chat message visible only to players on the same team.

**Event Data Structure:**
```python
{
    'event.type': int,           # Event type ID
    'event.client': Client,      # Client object of message sender
    'event.data': str            # Message text
}
```

**Available Properties:**
- `client.guid` - Unique player identifier (GUID)
- `client.name` - Player name
- `client.team` - Player's team (message recipients)
- `event.data` - Message text content

**Typical Usage:** Monitor team communication, analyze tactical coordination, moderate team chat.

**Example:**
```python
def onTeamSay(self, event):
    eventData = {
        'eventGeneratedUtc': datetime.utcnow().isoformat(),
        'eventType': 'EVT_CLIENT_TEAM_SAY',
        'communicationType': 'TEAM',
        'gameType': self._gameType,
        'serverId': self._serverId,
        'senderGuid': event.client.guid,
        'senderName': str(event.client.name),
        'senderTeam': event.client.team,
        'targetTeam': event.client.team,
        'message': str(event.data),
        'messageLength': len(str(event.data))
    }
```

---

### EVT_CLIENT_SQUAD_SAY

**Event Type:** Communication  
**Description:** Squad-only chat message visible only to players in the same squad (game-specific feature).

**Event Data Structure:**
```python
{
    'event.type': int,           # Event type ID
    'event.client': Client,      # Client object of message sender
    'event.data': str            # Message text
}
```

**Available Properties:**
- `client.guid` - Unique player identifier (GUID)
- `client.name` - Player name
- `client.team` - Player's team
- `client.squad` - Squad identifier (if available)
- `event.data` - Message text content

**Typical Usage:** Monitor squad communication in games with squad mechanics (e.g., Battlefield series).

**Note:** Only available in games with squad support.

**Example:**
```python
def onSquadSay(self, event):
    eventData = {
        'eventGeneratedUtc': datetime.utcnow().isoformat(),
        'eventType': 'EVT_CLIENT_SQUAD_SAY',
        'communicationType': 'SQUAD',
        'gameType': self._gameType,
        'serverId': self._serverId,
        'senderGuid': event.client.guid,
        'senderName': str(event.client.name),
        'senderTeam': event.client.team,
        'squadId': getattr(event.client, 'squad', None),
        'message': str(event.data),
        'messageLength': len(str(event.data))
    }
```

---

### EVT_CLIENT_PRIVATE_SAY

**Event Type:** Communication  
**Description:** Private message (whisper) sent from one player to another specific player.

**Event Data Structure:**
```python
{
    'event.type': int,           # Event type ID
    'event.client': Client,      # Client object of message sender
    'event.target': Client,      # Client object of message recipient (if available)
    'event.data': str            # Message text
}
```

**Available Properties:**
- `client.guid` - Sender's unique player identifier (GUID)
- `client.name` - Sender's player name
- `target.guid` - Recipient's GUID (if event.target available)
- `target.name` - Recipient's name (if event.target available)
- `event.data` - Message text content

**Typical Usage:** Monitor private messages for harassment detection, maintain private message logs for moderation.

**Example:**
```python
def onPrivateSay(self, event):
    eventData = {
        'eventGeneratedUtc': datetime.utcnow().isoformat(),
        'eventType': 'EVT_CLIENT_PRIVATE_SAY',
        'communicationType': 'PRIVATE',
        'gameType': self._gameType,
        'serverId': self._serverId,
        'senderGuid': event.client.guid,
        'senderName': str(event.client.name),
        'recipientGuid': event.target.guid if event.target else None,
        'recipientName': str(event.target.name) if event.target else None,
        'message': str(event.data),
        'messageLength': len(str(event.data))
    }
```

---

### EVT_CLIENT_RADIO

**Event Type:** Communication  
**Description:** Radio command issued by a player (game-specific feature for quick communication).

**Event Data Structure:**
```python
{
    'event.type': int,           # Event type ID
    'event.client': Client,      # Client object of player issuing command
    'event.data': str            # Radio command identifier or text
}
```

**Available Properties:**
- `client.guid` - Unique player identifier (GUID)
- `client.name` - Player name
- `client.team` - Player's team
- `event.data` - Radio command identifier or text

**Typical Usage:** Track use of radio commands, analyze communication patterns, monitor team coordination.

**Note:** Game-specific feature, available in games with radio command systems.

**Example:**
```python
def onRadio(self, event):
    eventData = {
        'eventGeneratedUtc': datetime.utcnow().isoformat(),
        'eventType': 'EVT_CLIENT_RADIO',
        'communicationType': 'RADIO',
        'gameType': self._gameType,
        'serverId': self._serverId,
        'senderGuid': event.client.guid,
        'senderName': str(event.client.name),
        'senderTeam': event.client.team,
        'radioCommand': str(event.data),
        'radioCommandCategory': None  # Parse from event.data if structured
    }
```

---

## Custom Plugin Events

These are custom events specific to the portal plugin implementation for map voting functionality.

### EVT_CLIENT_MAP_VOTE_LIKE

**Event Type:** Custom Plugin Event  
**Description:** Custom event triggered when a player uses the `!like` command to vote positively for the current map.

**Event Data Structure:**
```python
{
    'event.type': str,           # 'EVT_CLIENT_MAP_VOTE_LIKE'
    'event.client': Client,      # Client object of voting player
    'event.data': dict           # Vote details
}
```

**Available Properties:**
- `client.guid` - Unique player identifier (GUID)
- `client.name` - Player name
- Current map name (from `self.console.game.mapName`)

**Trigger:** Player executes `!like` command in chat.

**Typical Usage:** Track map popularity, generate map preference statistics, influence map rotation.

**Current Implementation:**
```python
def cmd_like(self, data, client, _):
    eventData = {
        'eventGeneratedUtc': datetime.utcnow().isoformat(),
        'eventType': 'EVT_CLIENT_MAP_VOTE_LIKE',
        'gameType': self._gameType,
        'serverId': self._serverId,
        'playerGuid': client.guid,
        'playerName': str(client.name),
        'mapName': self.console.game.mapName,
        'voteType': 'LIKE',
        'like': True
    }
```

---

### EVT_CLIENT_MAP_VOTE_DISLIKE

**Event Type:** Custom Plugin Event  
**Description:** Custom event triggered when a player uses the `!dislike` command to vote negatively for the current map.

**Event Data Structure:**
```python
{
    'event.type': str,           # 'EVT_CLIENT_MAP_VOTE_DISLIKE'
    'event.client': Client,      # Client object of voting player
    'event.data': dict           # Vote details
}
```

**Available Properties:**
- `client.guid` - Unique player identifier (GUID)
- `client.name` - Player name
- Current map name (from `self.console.game.mapName`)

**Trigger:** Player executes `!dislike` command in chat.

**Typical Usage:** Track map unpopularity, identify problematic maps, adjust map rotation.

**Current Implementation:**
```python
def cmd_dislike(self, data, client, _):
    eventData = {
        'eventGeneratedUtc': datetime.utcnow().isoformat(),
        'eventType': 'EVT_CLIENT_MAP_VOTE_DISLIKE',
        'gameType': self._gameType,
        'serverId': self._serverId,
        'playerGuid': client.guid,
        'playerName': str(client.name),
        'mapName': self.console.game.mapName,
        'voteType': 'DISLIKE',
        'like': False
    }
```

---

## Server and Game Events

These events track server state, game flow, and match progression for administration portal features.

### EVT_SERVER_STARTUP

**Event Type:** Server Event  
**Description:** Custom event triggered when the B3 bot connects to the game server and initializes.

**Event Data Structure:**
```python
{
    'event.type': str,           # 'EVT_SERVER_STARTUP'
    'serverId': str,             # Server identifier
    'gameType': str              # Game type
}
```

**Available Properties:**
- Server ID
- Game type
- Startup timestamp

**Trigger:** Plugin initialization (`onStartup` method).

**Typical Usage:** Track server uptime, monitor server restarts, initialize admin portal server status.

**Current Implementation:**
```python
def onStartup(self):
    eventData = {
        'eventGeneratedUtc': datetime.utcnow().isoformat(),
        'eventType': 'EVT_SERVER_STARTUP',
        'serverId': self._serverId,
        'gameType': self._gameType
    }
```

---

### EVT_GAME_MAP_CHANGE

**Event Type:** Game Event  
**Description:** Triggered when the server changes from one map to another.

**Event Data Structure:**
```python
{
    'event.type': int,           # Event type ID
    'event.data': dict           # Map change information
}
```

**Available Properties:**
- `event.data['new']` - New map name
- `event.data['old']` - Previous map name (may be empty on first map)
- `self.console.game.mapName` - Current map name
- `self.console.game.gameName` - Game mode name

**Typical Usage:** Track map rotation, monitor map changes for admin portal, enable map-specific configurations.

**Admin Portal Usage:** Display current map, show map history, track map change frequency.

**Example:**
```python
def onMapChange(self, event):
    console = self.console.game
    
    eventData = {
        'eventGeneratedUtc': datetime.utcnow().isoformat(),
        'eventType': 'EVT_GAME_MAP_CHANGE',
        'gameType': self._gameType,
        'serverId': self._serverId,
        'previousMap': event.data.get('old', '') if isinstance(event.data, dict) else '',
        'newMap': event.data.get('new', console.mapName) if isinstance(event.data, dict) else console.mapName,
        'mapName': str(console.mapName),
        'gameName': str(console.gameName) if console.gameName else ''
    }
```

---

### EVT_GAME_ROUND_START

**Event Type:** Game Event  
**Description:** Triggered when a new round starts in the game.

**Event Data Structure:**
```python
{
    'event.type': int,           # Event type ID
    'event.data': mixed          # Round information (game-specific)
}
```

**Available Properties:**
- `event.data` - Round number or round information (game-specific format)
- Current map name (from `self.console.game.mapName`)
- Current game mode (from `self.console.game.gameType`)

**Typical Usage:** Track round progression, initialize round statistics, monitor game flow.

**Admin Portal Usage:** Display "Round in Progress" status, show current round number, track round start times.

**Example:**
```python
def onRoundStart(self, event):
    eventData = {
        'eventGeneratedUtc': datetime.utcnow().isoformat(),
        'eventType': 'EVT_GAME_ROUND_START',
        'gameType': self._gameType,
        'serverId': self._serverId,
        'mapName': self.console.game.mapName,
        'roundInfo': str(event.data) if event.data else None
    }
```

---

### EVT_GAME_ROUND_END

**Event Type:** Game Event  
**Description:** Triggered when a round ends in the game.

**Event Data Structure:**
```python
{
    'event.type': int,           # Event type ID
    'event.data': mixed          # Round results (game-specific)
}
```

**Available Properties:**
- `event.data` - Round results, winning team, scores (game-specific format)
- Current map name (from `self.console.game.mapName`)

**Typical Usage:** Record round results, calculate statistics, determine winners.

**Admin Portal Usage:** Display round end status, show round results, track round completion times.

**Example:**
```python
def onRoundEnd(self, event):
    eventData = {
        'eventGeneratedUtc': datetime.utcnow().isoformat(),
        'eventType': 'EVT_GAME_ROUND_END',
        'gameType': self._gameType,
        'serverId': self._serverId,
        'mapName': self.console.game.mapName,
        'roundResults': str(event.data) if event.data else None
    }
```

---

### EVT_GAME_EXIT

**Event Type:** Game Event  
**Description:** Triggered when the game/match ends completely (all rounds finished).

**Event Data Structure:**
```python
{
    'event.type': int,           # Event type ID
    'event.data': mixed          # Game end information (game-specific)
}
```

**Available Properties:**
- `event.data` - Match results, final scores (game-specific format)
- Final map name
- Match duration information

**Typical Usage:** Record match completion, calculate final statistics, trigger map rotation.

**Admin Portal Usage:** Display match end status, show final results, track match completion.

**Example:**
```python
def onGameExit(self, event):
    eventData = {
        'eventGeneratedUtc': datetime.utcnow().isoformat(),
        'eventType': 'EVT_GAME_EXIT',
        'gameType': self._gameType,
        'serverId': self._serverId,
        'mapName': self.console.game.mapName,
        'gameResults': str(event.data) if event.data else None
    }
```

---

### EVT_GAME_WARMUP

**Event Type:** Game Event  
**Description:** Triggered when the game enters warmup period (pre-match preparation phase).

**Event Data Structure:**
```python
{
    'event.type': int,           # Event type ID
    'event.data': mixed          # Warmup information (game-specific)
}
```

**Available Properties:**
- `event.data` - Warmup duration or settings (game-specific)
- Current map name

**Typical Usage:** Track warmup periods, display server status during warmup.

**Admin Portal Usage:** Display "Warmup in Progress" status, show warmup timer if available.

**Example:**
```python
def onWarmup(self, event):
    eventData = {
        'eventGeneratedUtc': datetime.utcnow().isoformat(),
        'eventType': 'EVT_GAME_WARMUP',
        'gameType': self._gameType,
        'serverId': self._serverId,
        'mapName': self.console.game.mapName,
        'warmupInfo': str(event.data) if event.data else None
    }
```

---

### EVT_GAME_ROUND_PLAYER_SCORES

**Event Type:** Game Event  
**Description:** Triggered when player scores are updated during or after a round.

**Event Data Structure:**
```python
{
    'event.type': int,           # Event type ID
    'event.data': mixed          # Score information (game-specific)
}
```

**Available Properties:**
- `event.data` - Player scores, rankings, statistics (game-specific format)
- May contain multiple player score updates

**Typical Usage:** Track player performance, update leaderboards, calculate statistics.

**Admin Portal Usage:** Display live scoreboards, show historical score data, track player performance trends.

**Example:**
```python
def onRoundPlayerScores(self, event):
    eventData = {
        'eventGeneratedUtc': datetime.utcnow().isoformat(),
        'eventType': 'EVT_GAME_ROUND_PLAYER_SCORES',
        'gameType': self._gameType,
        'serverId': self._serverId,
        'mapName': self.console.game.mapName,
        'scoreData': event.data  # May be structured or need parsing
    }
```

---

## Event Schema Summary

### Common Event Schema

All events should be stored with these common fields:

```typescript
interface BaseEvent {
  eventId: string;                    // Unique UUID for this event
  eventGeneratedUtc: string;          // ISO 8601 timestamp (UTC)
  eventType: string;                  // Event type identifier
  serverId: string;                   // Server identifier
  gameType: string;                   // Game type (e.g., "cod4", "iourt43")
}
```

### Player Event Schema

Events involving players extend the base schema:

```typescript
interface PlayerEvent extends BaseEvent {
  playerGuid: string;                 // Player GUID (primary identifier)
  playerName: string;                 // Player name at time of event
  playerIpAddress?: string;           // IP address (optional for privacy)
  playerTeam?: string;                // Player team (if applicable)
}
```

### Communication Event Schema

Communication events have additional message fields:

```typescript
interface CommunicationEvent extends PlayerEvent {
  communicationType: string;          // PUBLIC, TEAM, SQUAD, PRIVATE, RADIO
  message: string;                    // Message text
  messageLength: number;              // Message length in characters
  recipientGuid?: string;             // For PRIVATE messages
  recipientName?: string;             // For PRIVATE messages
  targetTeam?: string;                // For TEAM messages
  squadId?: string;                   // For SQUAD messages
}
```

### Game Event Schema

Game and server events track game state:

```typescript
interface GameEvent extends BaseEvent {
  mapName?: string;                   // Current map name
  gameName?: string;                  // Game mode name
  roundInfo?: any;                    // Round-specific data
  gameResults?: any;                  // Match results data
  scoreData?: any;                    // Player score data
}
```

## Event Type Enumerations

### Player Lifecycle Event Types

```typescript
enum PlayerLifecycleEventType {
  EVT_CLIENT_CONNECT = "EVT_CLIENT_CONNECT",
  EVT_CLIENT_AUTH = "EVT_CLIENT_AUTH",
  EVT_CLIENT_JOIN = "EVT_CLIENT_JOIN",
  EVT_CLIENT_DISCONNECT = "EVT_CLIENT_DISCONNECT",
  EVT_CLIENT_NAME_CHANGE = "EVT_CLIENT_NAME_CHANGE"
}
```

### Communication Event Types

```typescript
enum CommunicationEventType {
  EVT_CLIENT_SAY = "EVT_CLIENT_SAY",
  EVT_CLIENT_TEAM_SAY = "EVT_CLIENT_TEAM_SAY",
  EVT_CLIENT_SQUAD_SAY = "EVT_CLIENT_SQUAD_SAY",
  EVT_CLIENT_PRIVATE_SAY = "EVT_CLIENT_PRIVATE_SAY",
  EVT_CLIENT_RADIO = "EVT_CLIENT_RADIO"
}
```

### Communication Types

```typescript
enum CommunicationType {
  PUBLIC = "PUBLIC",
  TEAM = "TEAM",
  SQUAD = "SQUAD",
  PRIVATE = "PRIVATE",
  RADIO = "RADIO"
}
```

### Custom Plugin Event Types

```typescript
enum CustomEventType {
  EVT_CLIENT_MAP_VOTE_LIKE = "EVT_CLIENT_MAP_VOTE_LIKE",
  EVT_CLIENT_MAP_VOTE_DISLIKE = "EVT_CLIENT_MAP_VOTE_DISLIKE"
}
```

### Server and Game Event Types

```typescript
enum ServerGameEventType {
  EVT_SERVER_STARTUP = "EVT_SERVER_STARTUP",
  EVT_GAME_MAP_CHANGE = "EVT_GAME_MAP_CHANGE",
  EVT_GAME_ROUND_START = "EVT_GAME_ROUND_START",
  EVT_GAME_ROUND_END = "EVT_GAME_ROUND_END",
  EVT_GAME_EXIT = "EVT_GAME_EXIT",
  EVT_GAME_WARMUP = "EVT_GAME_WARMUP",
  EVT_GAME_ROUND_PLAYER_SCORES = "EVT_GAME_ROUND_PLAYER_SCORES"
}
```

### Game Types

```typescript
enum GameType {
  COD4 = "cod4",
  IOURT41 = "iourt41",
  IOURT42 = "iourt42",
  IOURT43 = "iourt43",
  BF3 = "bf3",
  BFBC2 = "bfbc2",
  MOH = "moh",
  COD7 = "cod7"
}
```

## Implementation Notes

### Event Registration

To capture these events in the portal plugin, register them in the `onStartup` method:

```python
def onStartup(self):
    # Player lifecycle events
    self.registerEvent('EVT_CLIENT_CONNECT', self.onConnect)
    self.registerEvent('EVT_CLIENT_AUTH', self.onAuth)
    self.registerEvent('EVT_CLIENT_JOIN', self.onJoin)
    self.registerEvent('EVT_CLIENT_DISCONNECT', self.onDisconnect)
    self.registerEvent('EVT_CLIENT_NAME_CHANGE', self.onNameChange)
    
    # Communication events
    self.registerEvent('EVT_CLIENT_SAY', self.onSay)
    self.registerEvent('EVT_CLIENT_TEAM_SAY', self.onTeamSay)
    if self.console.getEventID('EVT_CLIENT_SQUAD_SAY'):
        self.registerEvent('EVT_CLIENT_SQUAD_SAY', self.onSquadSay)
    self.registerEvent('EVT_CLIENT_PRIVATE_SAY', self.onPrivateSay)
    if self.console.getEventID('EVT_CLIENT_RADIO'):
        self.registerEvent('EVT_CLIENT_RADIO', self.onRadio)
    
    # Game events
    self.registerEvent('EVT_GAME_MAP_CHANGE', self.onMapChange)
    self.registerEvent('EVT_GAME_ROUND_START', self.onRoundStart)
    self.registerEvent('EVT_GAME_ROUND_END', self.onRoundEnd)
    self.registerEvent('EVT_GAME_EXIT', self.onGameExit)
    self.registerEvent('EVT_GAME_WARMUP', self.onWarmup)
    if self.console.getEventID('EVT_GAME_ROUND_PLAYER_SCORES'):
        self.registerEvent('EVT_GAME_ROUND_PLAYER_SCORES', self.onRoundPlayerScores)
```

### Event Availability

- **All Games:** CONNECT, AUTH, JOIN, DISCONNECT, NAME_CHANGE, SAY, TEAM_SAY, MAP_CHANGE
- **Squad-Based Games:** SQUAD_SAY (Battlefield 3, BFBC2, etc.)
- **Radio Systems:** RADIO (Urban Terror, Call of Duty series)
- **Round-Based Games:** ROUND_START, ROUND_END, ROUND_PLAYER_SCORES
- **All Games with Matches:** GAME_EXIT, GAME_WARMUP

### Admin Portal Integration

The game events are specifically designed to support admin portal features:

1. **Current Server Status:**
   - EVT_SERVER_STARTUP - Server online indicator
   - EVT_GAME_MAP_CHANGE - Display current map
   - EVT_GAME_WARMUP - Show "Warmup in Progress"
   - EVT_GAME_ROUND_START - Show "Round X in Progress"

2. **Historical Views:**
   - EVT_GAME_MAP_CHANGE - Map rotation history
   - EVT_GAME_ROUND_END - Round completion history
   - EVT_GAME_ROUND_PLAYER_SCORES - Player performance over time

3. **Real-Time Monitoring:**
   - Player connections/disconnections
   - Active communication monitoring
   - Live game progression tracking

### Data Validation

When implementing the repository API, consider:

- **Required Fields:** eventId, eventGeneratedUtc, eventType, serverId, gameType
- **Player Identification:** playerGuid is the primary identifier (never null for player events)
- **Message Content:** Store raw message text, apply filtering at display time
- **Timestamps:** Always UTC in ISO 8601 format
- **Game-Specific Data:** Use flexible fields (JSON/JSONB) for event.data variations

