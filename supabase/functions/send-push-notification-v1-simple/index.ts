// Simplified Supabase Edge Function using FCM HTTP v1 API
// This version uses a simpler approach with service account JSON
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

// Alternative: Use Google Auth Library (if available in Deno)
// For now, we'll use a simpler approach with direct OAuth2 token

const SERVICE_ACCOUNT_JSON = Deno.env.get('FCM_SERVICE_ACCOUNT_JSON')
const PROJECT_ID = Deno.env.get('FCM_PROJECT_ID') || Deno.env.get('FIREBASE_PROJECT_ID') || ''

serve(async (req) => {
  try {
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
      {
        auth: {
          autoRefreshToken: false,
          persistSession: false
        }
      }
    )

    const { user_id, user_ids, title, body, data } = await req.json()
    const userIds = user_ids || (user_id ? [user_id] : [])

    if (userIds.length === 0) {
      return new Response(
        JSON.stringify({ error: 'No user IDs provided' }),
        { status: 400, headers: { 'Content-Type': 'application/json' } }
      )
    }

    // Get FCM tokens
    const { data: tokens, error } = await supabaseClient
      .from('user_fcm_tokens')
      .select('token, device_type')
      .in('user_id', userIds)

    if (error) throw error

    if (!tokens || tokens.length === 0) {
      return new Response(
        JSON.stringify({ message: 'No FCM tokens found', sent: 0 }),
        { status: 200, headers: { 'Content-Type': 'application/json' } }
      )
    }

    // Get access token and send notifications
    const accessToken = await getOAuthToken()
    const results = await sendNotifications(accessToken, tokens.map(t => t.token), title, body, data)

    return new Response(
      JSON.stringify({ 
        message: 'Notifications sent',
        sent: results.successCount,
        failed: results.failureCount
      }),
      { status: 200, headers: { 'Content-Type': 'application/json' } }
    )
  } catch (error) {
    console.error('Error:', error)
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 500, headers: { 'Content-Type': 'application/json' } }
    )
  }
})

async function getOAuthToken(): Promise<string> {
  if (!SERVICE_ACCOUNT_JSON) {
    throw new Error('FCM_SERVICE_ACCOUNT_JSON secret not set')
  }

  const serviceAccount = JSON.parse(SERVICE_ACCOUNT_JSON)
  
  // Use Google's OAuth2 token endpoint
  // We'll use a library approach or direct JWT signing
  // For Deno, we can use the jwt library or make a direct call
  
  // Simplified: Use Google's token endpoint with service account
  const jwt = await createServiceAccountJWT(serviceAccount)
  
  const response = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
      assertion: jwt,
    }).toString(),
  })

  const data = await response.json()
  if (!data.access_token) {
    throw new Error('Failed to get access token: ' + JSON.stringify(data))
  }
  
  return data.access_token
}

async function createServiceAccountJWT(serviceAccount: any): Promise<string> {
  // This is a simplified version - in production, use a proper JWT library
  // For Deno Edge Functions, you might need to use a different approach
  
  // For now, we'll provide instructions to use a JWT library
  // Or use Google's recommended approach
  
  // Alternative: Use deno.land/x/jose for JWT signing
  // For simplicity, we'll show the structure needed
  
  const header = { alg: 'RS256', typ: 'JWT' }
  const now = Math.floor(Date.now() / 1000)
  const payload = {
    iss: serviceAccount.client_email,
    scope: 'https://www.googleapis.com/auth/firebase.messaging',
    aud: 'https://oauth2.googleapis.com/token',
    exp: now + 3600,
    iat: now,
  }

  // Note: Proper JWT signing requires crypto operations
  // For Deno Edge Functions, consider using:
  // import { SignJWT } from 'https://deno.land/x/jose@v4.14.4/index.ts'
  
  // For now, return a placeholder - you'll need to implement proper JWT signing
  // or use a library that works in Deno Edge Functions
  throw new Error('JWT signing not implemented. See setup instructions.')
}

async function sendNotifications(
  accessToken: string,
  tokens: string[],
  title: string,
  body: string,
  data?: Record<string, any>
): Promise<{ successCount: number; failureCount: number }> {
  const FCM_URL = `https://fcm.googleapis.com/v1/projects/${PROJECT_ID}/messages:send`
  
  let successCount = 0
  let failureCount = 0

  for (const token of tokens) {
    const message = {
      message: {
        token: token,
        notification: { title, body },
        data: data ? Object.fromEntries(
          Object.entries(data).map(([k, v]) => [k, String(v)])
        ) : {},
        android: { priority: 'high' },
        apns: { headers: { 'apns-priority': '10' } },
      },
    }

    try {
      const response = await fetch(FCM_URL, {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${accessToken}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(message),
      })

      if (response.ok) {
        successCount++
      } else {
        const error = await response.text()
        console.error('FCM error:', error)
        failureCount++
      }
    } catch (error) {
      console.error('FCM send error:', error)
      failureCount++
    }
  }

  return { successCount, failureCount }
}



