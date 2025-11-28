# Verify Real-Time Task Updates Setup

## Quick Verification Steps

### Step 1: Verify REPLICA IDENTITY FULL is Set

Run this SQL in Supabase SQL Editor:

```sql
SELECT relreplident FROM pg_class WHERE relname = 'tasks';
```

**Expected Result:** Should return `'f'` (FULL)

**If it returns `'d'` (DEFAULT):**
```sql
ALTER TABLE tasks REPLICA IDENTITY FULL;
```

### Step 2: Check App Logs for Stream Activity

When you open the Tasks page, you should see these logs:

```
🔄 Starting stream for family tasks: [family-id]
✅ Stream created for family tasks: [family-id]
📥 Stream update received: X tasks for family [family-id]
✅ Successfully parsed X tasks from stream
📋 Task IDs: [task-ids]...
```

### Step 3: Test Real-Time Updates

1. Open app on Device 1 (User A)
2. Open app on Device 2 (User B - same family)
3. On Device 1: Create a new task
4. On Device 2: Watch the logs - you should see:
   ```
   📥 Stream update received: X tasks for family [family-id]
   ```

### Step 4: Verify Supabase Real-Time is Enabled

1. Go to Supabase Dashboard
2. Database → **Tables** (not Replication)
3. Find `tasks` table
4. Check if real-time is enabled (there should be an indicator)

**Note:** The "Replication" page is for external data replication, NOT for app real-time subscriptions.

## Troubleshooting

### If tasks don't update in real-time:

1. **Check REPLICA IDENTITY:**
   ```sql
   SELECT relreplident FROM pg_class WHERE relname = 'tasks';
   ```
   Must be `'f'` (FULL)

2. **Check RLS Policies:**
   Both users must be able to SELECT from tasks table
   ```sql
   SELECT * FROM tasks WHERE family_id = '[your-family-id]';
   ```
   Should return tasks for both users

3. **Check Stream Logs:**
   Look for "Stream update received" messages when tasks change

4. **Verify WebSocket Connection:**
   Check app logs for WebSocket connection errors

5. **Test with Supabase Dashboard:**
   - Go to Table Editor → tasks
   - Insert a new task manually
   - Check if it appears in the app without refresh

## Common Issues

### Issue: Stream never receives updates
**Solution:** Run `ALTER TABLE tasks REPLICA IDENTITY FULL;`

### Issue: Stream receives initial data but no updates
**Solution:** Check RLS policies - both users need SELECT permission

### Issue: Stream errors in logs
**Solution:** Check network connectivity and WebSocket support

