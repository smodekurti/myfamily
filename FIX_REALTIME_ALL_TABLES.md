# Fix Real-Time Updates for All Tables

## Problem
Real-time updates are not working for:
- ✅ Tasks (already fixed)
- ❌ Grocery Lists
- ❌ Grocery List Items
- ❌ Calendar Events

## Root Cause
These tables are missing `REPLICA IDENTITY FULL`, which is required for Supabase real-time subscriptions to work properly.

## Solution

### Step 1: Run SQL Migration

Run this SQL in your Supabase SQL Editor:

```sql
-- Enable real-time for all tables that use Supabase streams
ALTER TABLE tasks REPLICA IDENTITY FULL;
ALTER TABLE grocery_lists REPLICA IDENTITY FULL;
ALTER TABLE grocery_list_items REPLICA IDENTITY FULL;
ALTER TABLE calendar_events REPLICA IDENTITY FULL;
```

**How to run:**
1. Go to your Supabase project dashboard
2. Navigate to **SQL Editor** (left sidebar)
3. Click **New Query**
4. Copy and paste the SQL above
5. Click **Run** (or press Cmd/Ctrl + Enter)

### Step 2: Verify It Worked

Run this verification query:

```sql
SELECT relname, relreplident 
FROM pg_class 
WHERE relname IN ('tasks', 'grocery_lists', 'grocery_list_items', 'calendar_events');
```

**Expected Result:** All should return `'f'` (FULL), not `'d'` (DEFAULT)

### Step 3: Test Real-Time Updates

#### Test Grocery Lists:
1. Open app on Device 1 (User A)
2. Open app on Device 2 (User B - same family)
3. On Device 1: Create a new grocery list
4. On Device 2: The list should appear automatically within 1-2 seconds

#### Test Calendar Events:
1. Open app on Device 1 (User A)
2. Open app on Device 2 (User B - same family)
3. On Device 1: Create a new calendar event
4. On Device 2: The event should appear automatically within 1-2 seconds

## Tables That Use Real-Time Streams

### Tasks
- **Stream:** `streamTasksForFamily()`
- **Provider:** `familyTasksProvider`
- **Table:** `tasks`

### Grocery Lists
- **Streams:** 
  - `streamStandaloneListsForFamily()`
  - `streamAllListsForFamily()`
  - `streamListById()`
- **Providers:** 
  - `standaloneGroceryListsProvider`
  - `allGroceryListsProvider`
  - `groceryListProvider`
- **Tables:** `grocery_lists`, `grocery_list_items`

### Calendar Events
- **Stream:** `streamFamilyEvents()`
- **Provider:** `familyEventsProvider`
- **Table:** `calendar_events`

## Troubleshooting

If real-time still doesn't work after running the SQL:

1. **Check RLS policies:**
   - Make sure both users can SELECT from the tables
   - Verify the RLS policies allow viewing data in the same family

2. **Check app logs:**
   - Look for stream connection messages
   - Check for WebSocket connection errors

3. **Test with Supabase Dashboard:**
   - Go to Table Editor → [table name]
   - Insert a new record manually
   - Check if it appears in the app without refresh

## Related Files

- `enable_realtime_all_tables.sql` - SQL migration for all tables
- `lib/app/data/repositories/task_repository.dart` - Task streams
- `lib/app/data/repositories/grocery_list_repository.dart` - Grocery list streams
- `lib/app/data/repositories/calendar_repository.dart` - Calendar event streams

