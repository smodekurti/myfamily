# Fix Real-Time Task Updates - Action Required

## Current Status
The app code is correctly set up for real-time task updates using Supabase streams. However, tasks are not refreshing automatically, which means Supabase real-time needs to be configured.

## Required Actions

### Step 1: Enable REPLICA IDENTITY FULL (CRITICAL)

Run this SQL in your Supabase SQL Editor:

```sql
-- Enable real-time for tasks table
ALTER TABLE tasks REPLICA IDENTITY FULL;
```

**How to run:**
1. Go to your Supabase project dashboard
2. Navigate to **SQL Editor** (left sidebar)
3. Click **New Query**
4. Copy and paste the SQL above
5. Click **Run** (or press Cmd/Ctrl + Enter)

**Verify it worked:**
```sql
SELECT relreplident FROM pg_class WHERE relname = 'tasks';
```
This should return `'f'` (FULL) instead of `'d'` (DEFAULT).

### Step 2: Verify Real-Time is Enabled in Supabase Dashboard

1. Go to your Supabase project dashboard
2. Navigate to **Database** → **Tables** (left sidebar)
3. Find the `tasks` table
4. Click on the `tasks` table
5. Look for a **"Realtime"** toggle or indicator
6. Make sure it's **enabled/ON**

**Note:** If you don't see a Realtime toggle, it might be in **Database** → **Replication** settings, but the main place is in the table settings.

### Step 3: Verify RLS Policies Allow Access

Both users in the same family must be able to SELECT from the tasks table. Test this:

```sql
-- Replace [your-family-id] with an actual family ID
SELECT * FROM tasks WHERE family_id = '[your-family-id]';
```

This should return tasks for both users when logged in.

### Step 4: Test Real-Time Updates

1. Open the app on **Device 1** (User A)
2. Open the app on **Device 2** (User B - same family)
3. On **Device 1**: Create a new task
4. On **Device 2**: The task should appear **automatically** within 1-2 seconds without refreshing

## How It Works

1. **Stream Setup**: The `TaskRepository.streamTasksForFamily()` method creates a Supabase real-time stream
2. **Provider**: The `familyTasksProvider` (Riverpod) watches this stream
3. **UI**: The `TasksPage` widget watches the provider
4. **Updates**: When a task is created/updated/deleted, Supabase broadcasts the change via WebSocket
5. **Refresh**: The stream receives the update and emits new data, causing the UI to rebuild automatically

## Debugging

### Check App Logs

When you open the Tasks page, you should see:
```
🔄 Starting stream for family tasks: [family-id]
✅ Stream created for family tasks: [family-id]
📥 Stream update received: X tasks for family [family-id]
```

When a task is created on another device, you should see:
```
📥 Stream update received: X tasks for family [family-id]
✅ Successfully parsed X tasks from stream
```

### If Real-Time Still Doesn't Work

1. **Check WebSocket Connection**: Look for WebSocket errors in app logs
2. **Check Network**: Ensure your network allows WebSocket connections
3. **Verify Stream is Active**: Check logs for "Stream update received" messages
4. **Test with Supabase Dashboard**: 
   - Go to Table Editor → tasks
   - Insert a new task manually
   - Check if it appears in the app without refresh

## Code Status

✅ **Stream code is correct** - No code changes needed
✅ **Providers are set up correctly** - Using StreamProvider.family
✅ **Error handling is in place** - Streams will auto-reconnect
✅ **Logging is comprehensive** - Easy to debug issues

The only thing needed is **Supabase configuration** (Steps 1-2 above).



