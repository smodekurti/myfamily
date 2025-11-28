# Fix Real-Time Task Updates

## Problem
When a task is added on one device for a member, it doesn't automatically appear on the assigned member's device without restarting the app.

## Root Cause
The `tasks` table is missing `REPLICA IDENTITY FULL`, which is required for Supabase real-time subscriptions to work properly. Without this, Supabase cannot track changes to the table and send real-time updates to connected clients.

## Solution

### Step 1: Enable REPLICA IDENTITY for Tasks Table

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

### Step 2: Verify Real-Time is Enabled in Supabase

1. Go to your Supabase project dashboard
2. Navigate to **Database** → **Replication** (left sidebar)
3. Make sure the `tasks` table is listed and enabled for replication

If it's not enabled:
- Click on the `tasks` table
- Toggle **Enable Replication** to ON

### Step 3: Test Real-Time Updates

1. Open the app on two devices (or two simulators)
2. Log in with different users in the same family
3. On Device 1: Create a task and assign it to the user on Device 2
4. On Device 2: The task should appear automatically without refreshing or restarting the app

## What Was Fixed

1. **Created SQL migration** (`enable_tasks_realtime.sql`) to add `REPLICA IDENTITY FULL` to the tasks table
2. **Improved stream error handling** in `task_repository.dart` to make real-time subscriptions more robust
3. **Added better logging** to help debug real-time subscription issues

## Technical Details

### Why REPLICA IDENTITY FULL is Required

Supabase real-time uses PostgreSQL's logical replication to track changes. For tables without a primary key or with complex updates, `REPLICA IDENTITY FULL` ensures that all column values are included in the replication log, allowing Supabase to properly track and broadcast changes.

### How Real-Time Works in This App

1. The `TaskRepository.streamTasksForFamily()` method creates a Supabase real-time stream
2. The `familyTasksProvider` (Riverpod) watches this stream
3. The `TasksPage` widget watches the provider
4. When a task is created/updated/deleted, Supabase broadcasts the change
5. The stream receives the update and emits new data
6. Riverpod notifies all watchers, causing the UI to rebuild with the new data

### Stream Error Handling

The improved error handling ensures that:
- Stream errors are logged but don't close the connection
- Supabase automatically reconnects on connection loss
- Empty lists are returned on parsing errors instead of crashing

## Troubleshooting

If real-time still doesn't work after running the SQL:

1. **Check Supabase Replication settings:**
   - Database → Replication → Verify `tasks` table is enabled

2. **Check RLS policies:**
   - Make sure both users can SELECT from the tasks table
   - Verify the RLS policies allow viewing tasks in the same family

3. **Check network connectivity:**
   - Real-time uses WebSockets, ensure your network allows WebSocket connections
   - Check browser console or app logs for WebSocket connection errors

4. **Verify stream is active:**
   - Check app logs for "Starting stream for family tasks" messages
   - Look for "Received X tasks from stream" messages when tasks change

5. **Test with Supabase Dashboard:**
   - Go to Table Editor → tasks
   - Insert a new task manually
   - Check if it appears in the app without refresh

## Related Files

- `enable_tasks_realtime.sql` - SQL migration to enable real-time
- `lib/app/data/repositories/task_repository.dart` - Task repository with stream methods
- `lib/app/core/providers/providers.dart` - Riverpod providers that use the streams
- `lib/app/features/tasks/presentation/pages/tasks_page.dart` - Tasks page that displays the data

