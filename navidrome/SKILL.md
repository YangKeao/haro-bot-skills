---
name: navidrome
description: Query and browse music library from Navidrome server. Use when the user wants to search for songs, albums, artists, browse their starred/favorite music, or explore the music library. Triggers include "search music", "find songs", "my favorites", "starred music", "browse albums", "what artists do I have", or any task requiring Navidrome music library interaction.
allowed-tools: Bash(curl:*), Bash(navidrome:*)
---

# Navidrome Music Library Query

Interact with Navidrome music server using the Subsonic API to browse and search your music library.

## Configuration

Set these environment variables before using:

```bash
export NAVIDROME_URL="https://your-navidrome-server.com"
export NAVIDROME_USER="your-username"
export NAVIDROME_PASSWORD="your-password"
```

Or store credentials in `~/.navidrome/config.json`:

```json
{
  "url": "https://your-navidrome-server.com",
  "user": "your-username",
  "password": "your-password"
}
```

## Core API Pattern

All Subsonic API calls follow this pattern:

```bash
curl -s "${NAVIDROME_URL}/rest/<endpoint>?u=${NAVIDROME_USER}&p=${NAVIDROME_PASSWORD}&v=1.16.1&c=harobot&f=json"
```

Required parameters:
- `u` - Username
- `p` - Password (or use `t` and `s` for token auth)
- `v` - API version (use `1.16.1`)
- `c` - Client name
- `f` - Response format (`json`)

## Common Operations

### Check Server Status

```bash
curl -s "${NAVIDROME_URL}/rest/ping?u=${NAVIDROME_USER}&p=${NAVIDROME_PASSWORD}&v=1.16.1&c=harobot&f=json"
```

### Get Starred/Favorite Music

Returns all songs, albums, and artists the user has starred:

```bash
curl -s "${NAVIDROME_URL}/rest/getStarred2?u=${NAVIDROME_USER}&p=${NAVIDROME_PASSWORD}&v=1.16.1&c=harobot&f=json"
```

Response structure:
```json
{
  "subsonic-response": {
    "starred2": {
      "artist": [...],
      "album": [...],
      "song": [...]
    }
  }
}
```

### Search Music Library

Search across artists, albums, and songs:

```bash
curl -s "${NAVIDROME_URL}/rest/search3?query=<search-term>&u=${NAVIDROME_USER}&p=${NAVIDROME_PASSWORD}&v=1.16.1&c=harobot&f=json"
```

Optional parameters:
- `artistCount` - Max artists to return (default: 20)
- `albumCount` - Max albums to return (default: 20)
- `songCount` - Max songs to return (default: 20)

### Browse All Artists

```bash
curl -s "${NAVIDROME_URL}/rest/getArtists?u=${NAVIDROME_USER}&p=${NAVIDROME_PASSWORD}&v=1.16.1&c=harobot&f=json"
```

Returns artists grouped by first letter index.

### Get Albums by Artist

```bash
curl -s "${NAVIDROME_URL}/rest/getArtist?id=<artist-id>&u=${NAVIDROME_USER}&p=${NAVIDROME_PASSWORD}&v=1.16.1&c=harobot&f=json"
```

### Get Songs in Album

```bash
curl -s "${NAVIDROME_URL}/rest/getAlbum?id=<album-id>&u=${NAVIDROME_USER}&p=${NAVIDROME_PASSWORD}&v=1.16.1&c=harobot&f=json"
```

### Get Random Songs

```bash
curl -s "${NAVIDROME_URL}/rest/getRandomSongs?size=10&u=${NAVIDROME_USER}&p=${NAVIDROME_PASSWORD}&v=1.16.1&c=harobot&f=json"
```

### Get Recently Played

```bash
curl -s "${NAVIDROME_URL}/rest/getPlayQueue?u=${NAVIDROME_USER}&p=${NAVIDROME_PASSWORD}&v=1.16.1&c=harobot&f=json"
```

## Response Parsing

All responses are wrapped in `subsonic-response`:

```json
{
  "subsonic-response": {
    "status": "ok",      // "ok" or "failed"
    "version": "1.16.1",
    "type": "navidrome",
    "serverVersion": "0.59.0",
    "openSubsonic": true,
    // ... actual data
  }
}
```

Check `status` field to verify success.

## Song Object Fields

Common fields in song objects:

| Field | Description |
|-------|-------------|
| `id` | Unique song ID |
| `title` | Song title |
| `album` | Album name |
| `artist` | Artist name |
| `albumId` | Album ID |
| `artistId` | Artist ID |
| `track` | Track number |
| `year` | Release year |
| `duration` | Duration in seconds |
| `bitRate` | Bitrate in kbps |
| `contentType` | MIME type |
| `suffix` | File extension |
| `path` | File path |
| `starred` | Timestamp if starred |

## Example Usage

### List all starred songs with basic info

```bash
curl -s "${NAVIDROME_URL}/rest/getStarred2?u=${NAVIDROME_USER}&p=${NAVIDROME_PASSWORD}&v=1.16.1&c=harobot&f=json" | grep -oP '"title":"[^"]*".?"artist":"[^"]*".?"album":"[^"]*"'
```

### Search for a specific song

```bash
curl -s "${NAVIDROME_URL}/rest/search3?query=the%20architect&songCount=10&u=${NAVIDROME_USER}&p=${NAVIDROME_PASSWORD}&v=1.16.1&c=harobot&f=json"
```

## Error Handling

If `status` is `"failed"`, check the `error` object:

```json
{
  "subsonic-response": {
    "status": "failed",
    "error": {
      "code": 40,
      "message": "Wrong username or password"
    }
  }
}
```

Common error codes:
- `10` - Required parameter missing
- `20` - Incompatible protocol version
- `40` - Wrong username or password
- `50` - User is not authorized
- `60` - Trial period over
- `70` - Requested data not found

## Security Notes

1. Password is sent in plaintext over URL. Use HTTPS.
2. For better security, use token authentication:
   ```bash
   # Generate token
   SALT=$(openssl rand -hex 16)
   TOKEN=$(echo -n "${PASSWORD}${SALT}" | md5sum | cut -d' ' -f1)
   # Use token instead of password
   curl -s "${NAVIDROME_URL}/rest/ping?u=${USER}&t=${TOKEN}&s=${SALT}&v=1.16.1&c=harobot&f=json"
   ```
3. Never commit credentials to git.