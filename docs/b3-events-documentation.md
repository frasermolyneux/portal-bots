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
