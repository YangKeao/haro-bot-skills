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
```

### Get a Specific Recipe

```bash
MEALIE_URL=$(jq -r '.url' ~/.config/mealie/config.json)
MEALIE_TOKEN=$(jq -r '.token' ~/.config/mealie/config.json)

# Get by slug (use URL-encoded slug)
curl -s "${MEALIE_URL}/api/recipes/recipe-slug-here" \
  -H "Authorization: Bearer ${MEALIE_TOKEN}"
```

## Creating Recipes (Manual Entry)

**IMPORTANT**: Do NOT use URL import (`/api/recipes/create-url`) - it is unreliable. Always create recipes manually with the following two-step process.

### Step 1: Create Basic Recipe (POST)

Create the recipe with basic info to get a slug:

```bash
MEALIE_URL=$(jq -r '.url' ~/.config/mealie/config.json)
MEALIE_TOKEN=$(jq -r '.token' ~/.config/mealie/config.json)

curl -X POST "${MEALIE_URL}/api/recipes" \
  -H "Authorization: Bearer ${MEALIE_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Recipe Name 食谱中文名"
  }'
# Returns: "recipe-slug"
```

### Step 2: Update with Details (PATCH)

After creating, update with ingredients, instructions, and other details. **Best practice: include tags in this step to organize your recipe.**

```bash
MEALIE_URL=$(jq -r '.url' ~/.config/mealie/config.json)
MEALIE_TOKEN=$(jq -r '.token' ~/.config/mealie/config.json)

# First, get available tags to find the ones you want
curl -s "${MEALIE_URL}/api/organizers/tags?perPage=50" \
  -H "Authorization: Bearer ${MEALIE_TOKEN}" | \
  jq '.items[] | {id, groupId, name, slug}'

# Then update the recipe with all details including tags

curl -X PATCH "${MEALIE_URL}/api/recipes/recipe-slug" \
  -H "Authorization: Bearer ${MEALIE_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "description": "Recipe description here",
    "recipeYield": "4份",
    "orgURL": "https://example.com/original-recipe",
    "recipeIngredient": [
      {"quantity": 6, "note": "个 蛋黄", "referenceId": "f47ac10b-58cc-4372-a567-0e02b2c3d479"},
      {"quantity": 100, "note": "g 细砂糖", "referenceId": "f47ac10b-58cc-4372-a567-0e02b2c3d480"},
      {"quantity": 250, "note": "ml 牛奶", "referenceId": "f47ac10b-58cc-4372-a567-0e02b2c3d481"},
      {"note": "少许 盐（可选）", "referenceId": "f47ac10b-58cc-4372-a567-0e02b2c3d482"}
    ],
    "recipeInstructions": [
      {"id": "a1b2c3d4-0001-4000-8000-000000000001", "title": "", "summary": "", "text": "第一步：准备工作描述", "ingredientReferences": []},
      {"id": "a1b2c3d4-0001-4000-8000-000000000002", "title": "", "summary": "", "text": "第二步：烹饪步骤描述", "ingredientReferences": []}
    ],
    "tags": [
      {
        "id": "tag-id-from-api",
        "groupId": "group-id-from-api",
        "name": "Tag Name",
        "slug": "tag-slug"
      }
    ],
    "extras": {
      "参考来源": "https://other-source.com/recipe"
    }
  }'
```


**Recommended tags for different recipe types:**
- 肉类主菜 (rou-lei-zhu-cai) - Meat dishes
- 海鲜 - Seafood
- 素菜 - Vegetarian
- 主食 - Main course (rice, noodles, etc.)
- 汤羹 - Soups
- 异国风味 - International cuisine
- 甜品 - Desserts
### Description Format

**IMPORTANT**: The `description` field must follow a specific format for menu display.

**Format**: `食材1/食材2/食材3，口味1/口味2`

**Rules**:
- Use `/` (forward slash) to separate multiple ingredients or flavors
- Use `，` (Chinese comma) to separate ingredients from flavors
- No adjectives or decorative words (e.g., "经典", "美味", "诱人")
- Keep it concise for menu display
- Omit cooking methods (not needed for menu)

**Examples**:
- ✅ `火龙果/奶油/吉利丁，甜`
- ✅ `鸡肉/奶油/白葡萄酒/蘑菇，奶香/咸`
- ✅ `排骨，酸甜`
- ✅ `牛肉/红酒/胡萝卜，酒香/咸`
- ❌ `法式经典家常菜，鸡肉先用黄油煎至金黄...` (includes adjectives and cooking methods)
- ❌ `优雅的意大利奶冻配上粉色火龙果，视觉效果惊艳` (includes adjectives)
- ❌ `食材：火龙果、奶油；口味：甜` (too verbose, use `/` instead)

The description will be displayed in menu listings, so keep it clean and aesthetic.


### Ingredient Format Details

The `recipeIngredient` array supports two formats:

**Full format (with all fields):**

| Field | Type | Description |
|-------|------|-------------|
| `quantity` | number | Amount (e.g., 6, 100, 250). Use `null` for items without quantity |
| `note` | string | Unit + ingredient name (e.g., "个 蛋黄", "g 细砂糖", "ml 牛奶") |
| `referenceId` | UUID | Unique ID for this ingredient (generate with `uuidgen` or use any valid UUID) |

**Simplified format (also works):**
```json
{"note": "4只 鸡腿（带骨带皮）"}
```
The system will auto-generate missing fields. This is useful for quick recipe entry.

**Important**: The display will show as "{quantity} {note}" (e.g., "6 个 蛋黄", "100 g 细砂糖"). For simplified format, it displays just the note text.

Example ingredient formats:
- `{"quantity": 6, "note": "个 蛋黄", "referenceId": "..."}` → displays as "6 个 蛋黄"
- `{"quantity": 100, "note": "g 细砂糖", "referenceId": "..."}` → displays as "100 g 细砂糖"
- `{"note": "少许 盐（可选）", "referenceId": "..."}` → displays as "少许 盐（可选）"
- `{"note": "4只 鸡腿（带骨带皮）"}` → displays as "4只 鸡腿（带骨带皮）" (simplified)

### Instruction Format Details

The `recipeInstructions` array requires **all fields** - simplified format will cause errors:

| Field | Type | Description |
|-------|------|-------------|
| `id` | UUID | Unique ID for this step |
| `title` | string | Step title (usually empty "") |
| `summary` | string | Step summary (usually empty "") |
| `text` | string | Full instruction text |
| `ingredientReferences` | array | Links to ingredients (usually empty []) |

**⚠️ IMPORTANT**: Unlike ingredients, instructions do NOT support simplified format. You must include all fields:

```json
// ❌ WRONG - This will cause "TypeError" error
{"text": "第一步：准备工作"}

// ✅ CORRECT - Include all required fields
{"title": "", "summary": "", "text": "第一步：准备工作", "ingredientReferences": []}
```

### Adding Source URLs

- `orgURL`: The primary source URL (shows as clickable link in Mealie)
- `extras`: Object for additional metadata, can include multiple reference URLs

### Tags and Categories

Tags and categories help organize recipes. **Important**: They require full object format with all fields.

### Get Available Tags/Categories

```bash
MEALIE_URL=$(jq -r '.url' ~/.config/mealie/config.json)
MEALIE_TOKEN=$(jq -r '.token' ~/.config/mealie/config.json)

# Get tags with full info (including id and groupId)
curl -s "${MEALIE_URL}/api/organizers/tags?perPage=50" \
  -H "Authorization: Bearer ${MEALIE_TOKEN}" | \
  jq '.items[] | {id, groupId, name, slug}'

# Get categories with full info
curl -s "${MEALIE_URL}/api/organizers/categories?perPage=50" \
  -H "Authorization: Bearer ${MEALIE_TOKEN}" | \
  jq '.items[] | {id, groupId, name, slug}'
```

### Add Tags to Recipe

**⚠️ IMPORTANT**: Tags require the **full object** with `id`, `groupId`, `name`, and `slug`. Simplified format will cause TypeError.

```bash
# First, get the full tag info
TAG_INFO=$(curl -s "${MEALIE_URL}/api/organizers/tags?perPage=50" \
  -H "Authorization: Bearer ${MEALIE_TOKEN}" | \
  jq '.items[] | select(.slug == "tag-slug-here")')

# Then add to recipe
curl -X PATCH "${MEALIE_URL}/api/recipes/recipe-slug" \
  -H "Authorization: Bearer ${MEALIE_TOKEN}" \
  -H "Content-Type: application/json" \
  -d "{
    \"tags\": [
      {
        \"id\": \"tag-id-from-api\",
        \"groupId\": \"group-id-from-api\",
        \"name\": \"Tag Name\",
        \"slug\": \"tag-slug-here\"
      }
    ]
  }"
```

Example - Adding multiple tags to a recipe:
```bash
curl -X PATCH "${MEALIE_URL}/api/recipes/fa-shi-nai-you-tun-ji" \
  -H "Authorization: Bearer ${MEALIE_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "tags": [
      {
        "id": "71d6a565-3686-4146-b030-9f462c5400d9",
        "groupId": "64fd5e77-eebd-4002-b493-a66455a2a66c",
        "name": "肉类主菜",
        "slug": "rou-lei-zhu-cai"
      },
      {
        "id": "1e86de35-5fa6-41a0-9341-ebe1862a7d0f",
        "groupId": "64fd5e77-eebd-4002-b493-a66455a2a66c",
        "name": "异国风味",
        "slug": "yi-guo-feng-wei"
      }
    ]
  }'
```

The same format applies to categories (use `recipeCategory` field instead of `tags`).

### Create New Tag

If no existing tag fits your recipe, you can create a new one:

```bash
MEALIE_URL=$(jq -r '.url' ~/.config/mealie/config.json)
MEALIE_TOKEN=$(jq -r '.token' ~/.config/mealie/config.json)

# Create a new tag (only name is required)
curl -X POST "${MEALIE_URL}/api/organizers/tags" \
  -H "Authorization: Bearer ${MEALIE_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{"name": "新标签名"}'

# Response will include the full tag object with auto-generated id and slug:
# {
#   "name": "新标签名",
#   "groupId": "...",
#   "id": "...",
#   "slug": "xin-biao-qian-ming"
# }
```

After creating, use the returned object to add the tag to your recipe.

**Tip**: Use descriptive tag names in Chinese (e.g., "快手菜", "宴客菜", "宝宝辅食") for better organization.

### Create New Category

Same process for categories:

```bash
curl -X POST "${MEALIE_URL}/api/organizers/categories" \
  -H "Authorization: Bearer ${MEALIE_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{"name": "新分类名"}'
```

## Common Pitfalls

### 1. POST ignores most fields
When creating a recipe with POST, only the `name` field is processed. Other fields (ingredients, instructions, description) are ignored and replaced with default template values. **Always use two-step process**: POST to create, then PATCH to update.

### 2. Instruction format errors
Using simplified instruction format `{"text": "step"}` will return `{"detail":{"message":"Unknown Error","error":true,"exception":"TypeError"}}`. Always use the full format with all required fields.

### 3. PATCH returns null on success
A successful PATCH may return `null` in the response body. This doesn't mean failure - check the recipe with a GET request to verify the update.

### 4. jq not in PATH
Remember to export PATH after installing jq: `export PATH="$HOME/bin:$PATH"`. Or use full path `~/bin/jq`.

### 5. Token validation errors
If you get "Could not validate credentials", ensure:
- Token is copied correctly (no truncation)
- Config file has correct permissions (600)
- Using exact URL from config (no trailing slashes)

### 6. Tags/Categories format errors
Using simplified tag format `{"name": "Tag", "slug": "tag"}` will cause TypeError. You must include all fields:
- `id` - Tag ID from API
- `groupId` - Group ID from API
- `name` - Tag name
- `slug` - Tag slug

**Workflow**: First GET available tags from `/api/organizers/tags`, then use the full object in PATCH.

### 7. Wrong API endpoints for tags
- ❌ `/api/tags` - Returns HTML page, not API response
- ✅ `/api/organizers/tags` - Correct endpoint for tags
- ✅ `/api/organizers/categories` - Correct endpoint for categories

## Shopping Lists

### Get Shopping Lists
```bash
MEALIE_URL=$(jq -r '.url' ~/.config/mealie/config.json)
MEALIE_TOKEN=$(jq -r '.token' ~/.config/mealie/config.json)

curl -s "${MEALIE_URL}/api/households/shopping/lists" \
  -H "Authorization: Bearer ${MEALIE_TOKEN}"
```

### Add Recipe Ingredients to Shopping List
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
