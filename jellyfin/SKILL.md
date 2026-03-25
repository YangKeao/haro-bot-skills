---
name: jellyfin
description: Query and browse media library from Jellyfin server. Use when the user wants to search for movies, TV shows, episodes, browse their favorites, continue watching, or explore the media library. Triggers include "search movies", "find TV shows", "my favorites", "continue watching", "browse series", "what movies do I have", "list all videos", or any task requiring Jellyfin media library interaction.
allowed-tools: Bash(curl:*)
---

# Jellyfin Media Library Query

Interact with Jellyfin media server using the REST API to browse and search your media library.

## Configuration

Set these environment variables before using:

```bash
export JELLYFIN_URL="https://your-jellyfin-server.com"
export JELLYFIN_API_KEY="your-api-key"
export JELLYFIN_USER_ID="your-user-id"
```

Or store credentials in `~/.jellyfin/config.json`:

```json
{
  "url": "https://your-jellyfin-server.com",
  "api_key": "your-api-key",
  "user_id": "your-user-id"
}
```

### Getting API Key and User ID

1. **API Key**: Go to Jellyfin Dashboard -> API Keys -> Create new key
2. **User ID**: Use the API to list users:
   ```bash
   curl -s -H "X-Emby-Token: YOUR_API_KEY" "${JELLYFIN_URL}/Users"
   ```

## Core API Pattern

All Jellyfin API calls follow this pattern:

```bash
curl -s -H "X-Emby-Token: ${JELLYFIN_API_KEY}" "${JELLYFIN_URL}/<endpoint>"
```

Required header:
- `X-Emby-Token` - Your API key

## Common Operations

### Check Server Status

```bash
curl -s -H "X-Emby-Token: ${JELLYFIN_API_KEY}" "${JELLYFIN_URL}/System/Info"
```

### List All Users

```bash
curl -s -H "X-Emby-Token: ${JELLYFIN_API_KEY}" "${JELLYFIN_URL}/Users"
```

### List All Media Libraries

```bash
curl -s -H "X-Emby-Token: ${JELLYFIN_API_KEY}" "${JELLYFIN_URL}/Library/MediaFolders"
```

### List All Movies

```bash
curl -s -H "X-Emby-Token: ${JELLYFIN_API_KEY}" \
  "${JELLYFIN_URL}/Users/${JELLYFIN_USER_ID}/Items?Recursive=true&IncludeItemTypes=Movie&Fields=Name,ProductionYear,Overview"
```

### List All TV Series

```bash
curl -s -H "X-Emby-Token: ${JELLYFIN_API_KEY}" \
  "${JELLYFIN_URL}/Users/${JELLYFIN_USER_ID}/Items?Recursive=true&IncludeItemTypes=Series&Fields=Name,ProductionYear,Overview,Status"
```

### List All Episodes

```bash
curl -s -H "X-Emby-Token: ${JELLYFIN_API_KEY}" \
  "${JELLYFIN_URL}/Users/${JELLYFIN_USER_ID}/Items?Recursive=true&IncludeItemTypes=Episode&Fields=Name,SeriesName,SeasonName,SeasonNumber,EpisodeNumber"
```

### Search Media Library

```bash
curl -s -H "X-Emby-Token: ${JELLYFIN_API_KEY}" \
  "${JELLYFIN_URL}/Users/${JELLYFIN_USER_ID}/Items?Recursive=true&SearchTerm=<search-term>&Fields=Name,Type,ProductionYear,Overview"
```

### Get Continue Watching

```bash
curl -s -H "X-Emby-Token: ${JELLYFIN_API_KEY}" \
  "${JELLYFIN_URL}/Users/${JELLYFIN_USER_ID}/Items?Recursive=true&Filters=IsResumable&Fields=Name,Type,ProductionYear,UserData"
```

### Get Favorites

```bash
curl -s -H "X-Emby-Token: ${JELLYFIN_API_KEY}" \
  "${JELLYFIN_URL}/Users/${JELLYFIN_USER_ID}/Items?Recursive=true&Filters=IsFavorite&Fields=Name,Type,ProductionYear"
```

### Get Recently Added

```bash
curl -s -H "X-Emby-Token: ${JELLYFIN_API_KEY}" \
  "${JELLYFIN_URL}/Users/${JELLYFIN_USER_ID}/Items?Recursive=true&SortBy=DateCreated&SortOrder=Descending&Limit=20&Fields=Name,Type,ProductionYear"
```

### Get Item Details

```bash
curl -s -H "X-Emby-Token: ${JELLYFIN_API_KEY}" \
  "${JELLYFIN_URL}/Users/${JELLYFIN_USER_ID}/Items/<ITEM_ID>?Fields=Name,Type,ProductionYear,Overview,CommunityRating,Genres,People"
```

## Query Parameters Reference

| Parameter | Description | Example |
|-----------|-------------|---------|
| `Recursive` | Search recursively in subfolders | `true` |
| `IncludeItemTypes` | Filter by item type | `Movie,Series,Episode` |
| `Fields` | Additional fields to return | `Name,ProductionYear,Overview` |
| `SearchTerm` | Search query | `interstellar` |
| `Filters` | Filter results | `IsFavorite,IsResumable` |
| `SortBy` | Sort field | `DateCreated,Name,ProductionYear` |
| `SortOrder` | Sort direction | `Ascending,Descending` |
| `Limit` | Max results | `20` |
| `ParentId` | Filter by parent folder ID | `abc123` |

## Item Types

| Type | Description |
|------|-------------|
| `Movie` | Movies |
| `Series` | TV Shows |
| `Episode` | TV Episodes |
| `Season` | TV Seasons |
| `MusicAlbum` | Music Albums |
| `MusicArtist` | Music Artists |
| `Audio` | Music Tracks |
| `Folder` | Folders |
| `CollectionFolder` | Library Folders |

## Available Fields

| Field | Description |
|-------|-------------|
| `Name` | Item name |
| `Type` | Item type |
| `ProductionYear` | Release year |
| `Overview` | Description/summary |
| `CommunityRating` | User rating (0-10) |
| `OfficialRating` | Content rating (PG, R, etc) |
| `Genres` | Genre tags |
| `People` | Cast and crew |
| `RunTimeTicks` | Duration (1 second = 10,000,000 ticks) |
| `Path` | File path |
| `UserData` | User-specific data (played, favorite, etc) |

## UserData Fields

The `UserData` object contains user-specific information:

| Field | Description |
|-------|-------------|
| `Played` | Whether item has been played |
| `PlayCount` | Number of times played |
| `IsFavorite` | Whether item is favorited |
| `PlaybackPositionTicks` | Current playback position |
| `LastPlayedDate` | Last played timestamp |
| `UnplayedItemCount` | Number of unplayed items (for series) |

## Example Usage

### List all movies with ratings

```bash
curl -s -H "X-Emby-Token: ${JELLYFIN_API_KEY}" \
  "${JELLYFIN_URL}/Users/${JELLYFIN_USER_ID}/Items?Recursive=true&IncludeItemTypes=Movie&Fields=Name,ProductionYear,CommunityRating" \
  | perl -e 'use JSON::PP; my $d=decode_json(do{local$/;<STDIN>}); foreach(@{$d->{Items}}){print "[$_->{ProductionYear}] $_->{Name} (rating: $_->{CommunityRating})\n"}'
```

### Search for a specific movie

```bash
curl -s -H "X-Emby-Token: ${JELLYFIN_API_KEY}" \
  "${JELLYFIN_URL}/Users/${JELLYFIN_USER_ID}/Items?Recursive=true&SearchTerm=matrix&IncludeItemTypes=Movie&Fields=Name,ProductionYear"
```

### Get unwatched episodes

```bash
curl -s -H "X-Emby-Token: ${JELLYFIN_API_KEY}" \
  "${JELLYFIN_URL}/Users/${JELLYFIN_USER_ID}/Items?Recursive=true&IncludeItemTypes=Episode&Filters=IsUnplayed&Fields=Name,SeriesName,SeasonNumber,EpisodeNumber"
```

### Get episodes of a specific series

```bash
curl -s -H "X-Emby-Token: ${JELLYFIN_API_KEY}" \
  "${JELLYFIN_URL}/Users/${JELLYFIN_USER_ID}/Items?Recursive=true&IncludeItemTypes=Episode&ParentId=<SERIES_ID>&Fields=Name,SeasonNumber,EpisodeNumber"
```

### Get recently watched

```bash
curl -s -H "X-Emby-Token: ${JELLYFIN_API_KEY}" \
  "${JELLYFIN_URL}/Users/${JELLYFIN_USER_ID}/Items?Recursive=true&SortBy=LastPlayedDate&SortOrder=Descending&Limit=20&Fields=Name,Type,ProductionYear"
```

## Image URLs

Get images for items:

```bash
# Primary (poster) image
curl -s -H "X-Emby-Token: ${JELLYFIN_API_KEY}" \
  "${JELLYFIN_URL}/Items/<ITEM_ID>/Images/Primary?width=300&quality=90"

# Backdrop image
curl -s -H "X-Emby-Token: ${JELLYFIN_API_KEY}" \
  "${JELLYFIN_URL}/Items/<ITEM_ID>/Images/Backdrop?width=1920&quality=90"

# Thumbnail
curl -s -H "X-Emby-Token: ${JELLYFIN_API_KEY}" \
  "${JELLYFIN_URL}/Items/<ITEM_ID>/Images/Thumb?width=400&quality=90"
```

## Error Handling

Jellyfin returns HTTP status codes:
- `200` - Success
- `401` - Unauthorized (invalid API key)
- `404` - Not found
- `500` - Server error

## Security Notes

1. API keys have full access to the server. Keep them secure.
2. Use HTTPS to encrypt API communication.
3. Create separate API keys for different applications.
4. Never commit API keys to git.