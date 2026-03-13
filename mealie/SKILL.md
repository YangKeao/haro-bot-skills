---
name: mealie
description: Interact with Mealie recipe manager. Use when the user wants to search recipes, create recipes, add items to shopping lists, get today's meal plan, browse categories/tags, or manage their recipe collection. Triggers include "search recipes", "find a recipe", "add to shopping list", "what's for dinner", "today's meal", "create recipe", or any task requiring Mealie interaction.
allowed-tools: Bash(curl:*), Bash(mealie:*), Bash(jq:*)
---

# Mealie Recipe Manager Integration

Interact with your Mealie instance to manage recipes, shopping lists, and meal plans.

## Prerequisites

This skill requires `jq` for JSON parsing. Install it if not available:
```bash
# Download to ~/bin
mkdir -p ~/bin
curl -sL https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64 -o ~/bin/jq
chmod +x ~/bin/jq
export PATH="$HOME/bin:$PATH"
```

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
# Load config using jq
MEALIE_URL=$(jq -r '.url' ~/.config/mealie/config.json)
MEALIE_TOKEN=$(jq -r '.token' ~/.config/mealie/config.json)

# Make API call
curl -s "${MEALIE_URL}/api/<endpoint>" \
  -H "Authorization: Bearer ${MEALIE_TOKEN}" \
  -H "Content-Type: application/json"
```

## Common Operations

### Check Server Status
```bash
MEALIE_URL=$(jq -r '.url' ~/.config/mealie/config.json)
MEALIE_TOKEN=$(jq -r '.token' ~/.config/mealie/config.json)

curl -s "${MEALIE_URL}/api/app/about" \
  -H "Authorization: Bearer ${MEALIE_TOKEN}"
```

### List All Recipes
```bash
MEALIE_URL=$(jq -r '.url' ~/.config/mealie/config.json)
MEALIE_TOKEN=$(jq -r '.token' ~/.config/mealie/config.json)

# Get all recipe names
curl -s "${MEALIE_URL}/api/recipes?perPage=100" \
  -H "Authorization: Bearer ${MEALIE_TOKEN}" | \
  jq -r '.items[].name'

# Get recipe names with slugs
curl -s "${MEALIE_URL}/api/recipes?perPage=100" \
  -H "Authorization: Bearer ${MEALIE_TOKEN}" | \
  jq -r '.items[] | "\(.name) (\(.slug))"'
```

### Search Recipes
Search across all recipes:

```bash
MEALIE_URL=$(jq -r '.url' ~/.config/mealie/config.json)
MEALIE_TOKEN=$(jq -r '.token' ~/.config/mealie/config.json)

# Search and show names
curl -s "${MEALIE_URL}/api/recipes?search=pasta&perPage=20" \
  -H "Authorization: Bearer ${MEALIE_TOKEN}" | \
  jq -r '.items[].name'

# Search with URL encoding for Chinese
curl -s "${MEALIE_URL}/api/recipes?search=%E7%81%AB%E9%94%85&perPage=20" \
  -H "Authorization: Bearer ${MEALIE_TOKEN}" | \
  jq -r '.items[].name'
```

Optional parameters:
- `search` - Search query (URL encode for special characters)
- `categories` - Filter by category (comma-separated)
- `tags` - Filter by tag (comma-separated)
- `page`, `perPage` - Pagination

### Get Single Recipe
```bash
MEALIE_URL=$(jq -r '.url' ~/.config/mealie/config.json)
MEALIE_TOKEN=$(jq -r '.token' ~/.config/mealie/config.json)

# Get by slug
curl -s "${MEALIE_URL}/api/recipes/spaghetti-bolognese" \
  -H "Authorization: Bearer ${MEALIE_TOKEN}" | \
  jq '{name, description, recipeIngredient: [.recipeIngredient[].note], recipeInstructions: [.recipeInstructions[].text]}'
```

### Create Recipe from URL
Import a recipe from a website:

```bash
MEALIE_URL=$(jq -r '.url' ~/.config/mealie/config.json)
MEALIE_TOKEN=$(jq -r '.token' ~/.config/mealie/config.json)

curl -X POST "${MEALIE_URL}/api/recipes/create-url" \
  -H "Authorization: Bearer ${MEALIE_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{"url":"https://www.allrecipes.com/recipe/12345"}'
```

Returns the slug of the created recipe.

### Create Recipe (JSON)
Create a new recipe directly:

```bash
MEALIE_URL=$(jq -r '.url' ~/.config/mealie/config.json)
MEALIE_TOKEN=$(jq -r '.token' ~/.config/mealie/config.json)

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
MEALIE_URL=$(jq -r '.url' ~/.config/mealie/config.json)
MEALIE_TOKEN=$(jq -r '.token' ~/.config/mealie/config.json)

curl -s "${MEALIE_URL}/api/households/mealplans/today" \
  -H "Authorization: Bearer ${MEALIE_TOKEN}" | \
  jq '.[] | {date: .date, recipe: .recipe.name}'
```

### Get Shopping Lists
```bash
MEALIE_URL=$(jq -r '.url' ~/.config/mealie/config.json)
MEALIE_TOKEN=$(jq -r '.token' ~/.config/mealie/config.json)

curl -s "${MEALIE_URL}/api/households/shopping/lists" \
  -H "Authorization: Bearer ${MEALIE_TOKEN}" | \
  jq '.[] | {id, name}'
```

### Add Item to Shopping List
```bash
MEALIE_URL=$(jq -r '.url' ~/.config/mealie/config.json)
MEALIE_TOKEN=$(jq -r '.token' ~/.config/mealie/config.json)

# Get first shopping list ID
LIST_ID=$(curl -s "${MEALIE_URL}/api/households/shopping/lists" \
  -H "Authorization: Bearer ${MEALIE_TOKEN}" | \
  jq -r '.[0].id')

# Add item
curl -X POST "${MEALIE_URL}/api/households/shopping/items" \
  -H "Authorization: Bearer ${MEALIE_TOKEN}" \
  -H "Content-Type: application/json" \
  -d "{\"shopping_list_id\":\"${LIST_ID}\",\"note\":\"milk\",\"quantity\":1}"
```

### Add Recipe to Shopping List
```bash
MEALIE_URL=$(jq -r '.url' ~/.config/mealie/config.json)
MEALIE_TOKEN=$(jq -r '.token' ~/.config/mealie/config.json)

# Get shopping list ID
LIST_ID=$(curl -s "${MEALIE_URL}/api/households/shopping/lists" \
  -H "Authorization: Bearer ${MEALIE_TOKEN}" | \
  jq -r '.[0].id')

# Get recipe ID by slug
RECIPE_ID=$(curl -s "${MEALIE_URL}/api/recipes/spaghetti-bolognese" \
  -H "Authorization: Bearer ${MEALIE_TOKEN}" | \
  jq -r '.id')

# Add recipe ingredients to list
curl -X POST "${MEALIE_URL}/api/households/shopping/items" \
  -H "Authorization: Bearer ${MEALIE_TOKEN}" \
  -H "Content-Type: application/json" \
  -d "{\"shopping_list_id\":\"${LIST_ID}\",\"recipe_references\":[{\"recipe_id\":\"${RECIPE_ID}\",\"recipe_quantity\":1}]}"
```

### Get Categories
```bash
MEALIE_URL=$(jq -r '.url' ~/.config/mealie/config.json)
MEALIE_TOKEN=$(jq -r '.token' ~/.config/mealie/config.json)

curl -s "${MEALIE_URL}/api/categories" \
  -H "Authorization: Bearer ${MEALIE_TOKEN}" | \
  jq '.[].name'
```

### Get Tags
```bash
MEALIE_URL=$(jq -r '.url' ~/.config/mealie/config.json)
MEALIE_TOKEN=$(jq -r '.token' ~/.config/mealie/config.json)

curl -s "${MEALIE_URL}/api/tags" \
  -H "Authorization: Bearer ${MEALIE_TOKEN}" | \
  jq '.[].name'
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

Use `jq` to extract data:
```bash
# Get total count
jq '.total'

# Get all item names
jq -r '.items[].name'

# Get first item's id
jq -r '.items[0].id'

# Pretty print a recipe
jq '{name, description, ingredients: [.recipeIngredient[].note]}'
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

Check for errors with jq:
```bash
curl -s "${MEALIE_URL}/api/recipes" \
  -H "Authorization: Bearer ${MEALIE_TOKEN}" | \
  jq 'if .detail then "Error: \(.detail.message)" else . end'
```

## Security Notes
1. Keep `~/.config/mealie/config.json` permissions restricted (600)
2. Token has long expiration but should be rotated periodically
3. Use HTTPS for all API calls
4. Never commit config file to git
