---
name: mealie
description: Interact with Mealie recipe manager. Use when the user wants to search recipes, create recipes, add items to shopping lists, get today's meal plan, browse categories/tags, or manage their recipe collection. Triggers include "search recipes", "find a recipe", "add to shopping list", "what's for dinner", "today's meal", "create recipe", or any task requiring Mealie interaction.
allowed-tools: Bash(curl:*), Bash(mealie:*)
---

# Mealie Recipe Manager Integration

Interact with your Mealie instance to manage recipes, shopping lists, and meal plans.

## Configuration

Credentials are stored in `~/.config/mealie/config.json`:

```json
{
  "url": "https://mealie.keao.space",
  "token": "your-api-token-here"
}
```

The config file should have restricted permissions (chmod 600).

## Core API Pattern

All Mealie API calls follow this pattern:

```bash
# Load config
MEALIE_URL=$(grep -o '"url"[[:space:]]*:[[:space:]]*"[^"]*"' ~/.config/mealie/config.json | cut -d'"' -f4)
MEALIE_TOKEN=$(grep -o '"token"[[:space:]]*:[[:space:]]*"[^"]*"' ~/.config/mealie/config.json | cut -d'"' -f4)

# Make API call
curl -s "${MEALIE_URL}/api/<endpoint>" \
  -H "Authorization: Bearer ${MEALIE_TOKEN}" \
  -H "Content-Type: application/json"
```

## Common Operations

### Check Server Status
```bash
curl -s "${MEALIE_URL}/api/app/about" \
  -H "Authorization: Bearer ${MEALIE_TOKEN}"
```

### Search Recipes
Search across all recipes:

```bash
curl -s "${MEALIE_URL}/api/recipes?search=pasta&page=1&perPage=20" \
  -H "Authorization: Bearer ${MEALIE_TOKEN}"
```

Optional parameters:
- `search` - Search query
- `categories` - Filter by category (comma-separated)
- `tags` - Filter by tag (comma-separated)
- `page`, `perPage` - Pagination

### Get Single Recipe
```bash
curl -s "${MEALIE_URL}/api/recipes/{slug_or_id}" \
  -H "Authorization: Bearer ${MEALIE_TOKEN}"
```

### Create Recipe from URL
Import a recipe from a website:

```bash
curl -X POST "${MEALIE_URL}/api/recipes/create-url" \
  -H "Authorization: Bearer ${MEALIE_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{"url":"https://www.allrecipes.com/recipe/12345"}'
```

Returns the slug of the created recipe.

### Create Recipe (JSON)
Create a new recipe directly:

```bash
curl -X POST "${MEALIE_URL}/api/recipes" \
  -H "Authorization: Bearer ${MEALIE_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "My Recipe",
    "description": "A delicious meal",
    "recipeIngredient": [
      {"note": "2 cups flour"},
      {"note": "1 cup sugar"}
    ],
    "recipeInstructions": [
      {"text": "Mix ingredients"},
      {"text": "Bake at 350F for 30 minutes"}
    ]
  }'
```

### Get Today's Meal Plan
```bash
curl -s "${MEALIE_URL}/api/households/mealplans/today" \
  -H "Authorization: Bearer ${MEALIE_TOKEN}"
```

### Get Shopping Lists
```bash
curl -s "${MEALIE_URL}/api/households/shopping/lists" \
  -H "Authorization: Bearer ${MEALIE_TOKEN}"
```

### Add Recipe to Shopping List
```bash
# First get shopping list ID
LIST_ID=$(curl -s "${MEALIE_URL}/api/households/shopping/lists" \
  -H "Authorization: Bearer ${MEALIE_TOKEN}" | \
  grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)

# Add recipe ingredients to list
curl -X POST "${MEALIE_URL}/api/households/shopping/items" \
  -H "Authorization: Bearer ${MEALIE_TOKEN}" \
  -H "Content-Type: application/json" \
  -d "{\"shopping_list_id\":\"${LIST_ID}\",\"recipe_references\":[{\"recipe_id\":\"RECIPE_ID\",\"recipe_quantity\":1}]}"
```

### Add Item to Shopping List
```bash
LIST_ID=$(curl -s "${MEALIE_URL}/api/households/shopping/lists" \
  -H "Authorization: Bearer ${MEALIE_TOKEN}" | \
  grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)

curl -X POST "${MEALIE_URL}/api/households/shopping/items" \
  -H "Authorization: Bearer ${MEALIE_TOKEN}" \
  -H "Content-Type: application/json" \
  -d "{\"shopping_list_id\":\"${LIST_ID}\",\"note\":\"milk\",\"quantity\":1}"
```

### Get Categories
```bash
curl -s "${MEALIE_URL}/api/categories" \
  -H "Authorization: Bearer ${MEALIE_TOKEN}"
```

### Get Tags
```bash
curl -s "${MEALIE_URL}/api/tags" \
  -H "Authorization: Bearer ${MEALIE_TOKEN}"
```

## Response Format
Most responses follow this pattern:

```json
{
  "items": [...],
  "page": 1,
  "per_page": 20,
  "total": 100
}
```

## Error Handling
Check HTTP status codes:
- `200` - Success
- `201` - Created
- `400` - Bad Request (invalid data)
- `401` - Unauthorized (bad token)
- `404` - Not Found
- `422` - Validation Error

Error response body:
```json
{
  "detail": {
    "message": "Error description",
    "error": true
  }
}
```

## Security Notes
1. Keep `~/.config/mealie/config.json` permissions restricted (600)
2. Token has long expiration but should be rotated periodically
3. Use HTTPS for all API calls
4. Never commit config file to git
