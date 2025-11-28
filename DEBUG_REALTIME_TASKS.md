# Debug Real-Time Tasks Not Updating

Since you've confirmed REPLICA IDENTITY FULL is set and realtime is enabled, let's debug why tasks aren't updating automatically.

## Step 1: Check App Logs

When you open the Tasks page, you should see these logs:
```
🔄 Starting stream for family tasks: [family-id]
✅ Stream created for family tasks: [family-id]
📥 Stream update received: X tasks for family [family-id]
```

**If you DON'T see "📥 Stream update received" when a task is created on another device, the stream isn't receiving updates.**

## Step 2: Verify RLS Policies

The most common issue is RLS (Row Level Security) policies blocking realtime updates.

### Check if RLS is enabled:
```sql
SELECT tablename, rowsecurity 
FROM pg_tables 
WHERE tablename = 'tasks';
```

### Check your RLS policies:
```sql
SELECT * FROM pg_policies WHERE tablename = 'tasks';
```

### Test if both users can SELECT:
```sql
-- Run this as User A (replace with actual family_id)
SELECT * FROM tasks WHERE family_id = '[your-family-id]';

-- Run this as User B (same family_id)
SELECT * FROM tasks WHERE family_id = '[your-family-id]';
```

**Both queries should return the same tasks.**

### If RLS policies are blocking:

You need a policy that allows SELECT for family members:

```sql
-- Allow family members to view tasks in their family
CREATE POLICY "Family members can view tasks"
ON tasks
FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM families
    WHERE families.id = tasks.family_id
    AND families.members ? auth.uid()::text
  )
);
```

## Step 3: Test Realtime Connection

### Option A: Test with Supabase Dashboard

1. Open Supabase Dashboard → Table Editor → tasks
2. Insert a new task manually
3. Check your app logs - you should see:
   ```
   📥 Stream update received: X tasks for family [family-id]
   ```

### Option B: Test with SQL

1. In Supabase SQL Editor, run:
   ```sql
   INSERT INTO tasks (family_id, title, assigned_to, created_by, status, priority, category, points, created_at, updated_at)
   VALUES ('[your-family-id]', 'Test Task', '[user-id]', '[user-id]', 'pending', 'medium', 'chore', 10, NOW(), NOW());
   ```
2. Check your app logs immediately - you should see the stream update

## Step 4: Check WebSocket Connection

Real-time uses WebSockets. Check your app logs for:
- WebSocket connection errors
- Connection timeout errors
- Network errors

## Step 5: Verify Stream is Active

The stream should stay active as long as:
1. The TasksPage is open
2. The `familyTasksProvider` is being watched
3. The user is authenticated

Check if the stream is being recreated multiple times (this would indicate it's being closed/reopened).

## Step 6: Test with Minimal Code

Try creating a simple test to isolate the issue:

```dart
// In your test/debug code
final stream = Supabase.instance.client
    .from('tasks')
    .stream(primaryKey: ['id'])
    .eq('family_id', '[your-family-id]');

stream.listen((data) {
  print('📥 Stream update: ${data.length} tasks');
}, onError: (error) {
  print('❌ Stream error: $error');
});
```

Then manually insert a task in Supabase Dashboard and see if the stream receives it.

## Common Issues and Fixes

### Issue 1: RLS Policies Too Restrictive
**Fix:** Ensure RLS policies allow SELECT for all family members

### Issue 2: Stream Not Staying Active
**Fix:** Ensure the provider is being watched continuously (not recreated)

### Issue 3: WebSocket Connection Issues
**Fix:** Check network/firewall settings, ensure WebSockets are allowed

### Issue 4: Realtime Not Actually Enabled
**Fix:** Double-check in Supabase Dashboard → Database → Tables → tasks → Realtime toggle

### Issue 5: REPLICA IDENTITY Not Set
**Fix:** Run `ALTER TABLE tasks REPLICA IDENTITY FULL;` again

## Next Steps

1. Check your app logs when creating a task on another device
2. Verify RLS policies allow both users to SELECT
3. Test with Supabase Dashboard manual insert
4. Share the logs you see (or don't see) so we can diagnose further


