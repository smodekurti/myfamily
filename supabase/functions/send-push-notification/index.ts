// Supabase Edge Function to send push notifications via FCM API v1
// Uses Service Account credentials (not deprecated Server Key)
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { SignJWT, importPKCS8 } from 'https://deno.land/x/jose@v4.14.4/index.ts'

const SERVICE_ACCOUNT_JSON = Deno.env.get('FCM_SERVICE_ACCOUNT_JSON')
const PROJECT_ID = Deno.env.get('FCM_PROJECT_ID') || ''

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

    // Get FCM tokens for all users
    const { data: tokens, error } = await supabaseClient
      .from('user_fcm_tokens')
      .select('token, device_type')
      .in('user_id', userIds)

    if (error) {
      throw error
    }

    if (!tokens || tokens.length === 0) {
      return new Response(
        JSON.stringify({ message: 'No FCM tokens found for users', sent: 0 }),
        { status: 200, headers: { 'Content-Type': 'application/json' } }
      )
    }

    // Get OAuth access token
    const accessToken = await getOAuthToken()
    
    // Send notifications via FCM API v1
    const fcmTokens = tokens.map((t: { token: string }) => t.token)
    const results = await sendFCMNotificationsV1(accessToken, fcmTokens, title, body, data)

    return new Response(
      JSON.stringify({ 
        message: 'Notifications sent',
        sent: results.successCount,
        failed: results.failureCount
      }),
      { status: 200, headers: { 'Content-Type': 'application/json' } }
    )
  } catch (error: unknown) {
    console.error('Error:', error)
    const errorMessage = error instanceof Error ? error.message : 'Unknown error'
    return new Response(
      JSON.stringify({ error: errorMessage }),
      { status: 500, headers: { 'Content-Type': 'application/json' } }
    )
  }
})

async function getOAuthToken(): Promise<string> {
  if (!SERVICE_ACCOUNT_JSON) {
    throw new Error('FCM_SERVICE_ACCOUNT_JSON secret not configured. See PUSH_NOTIFICATIONS_SETUP_V1.md')
  }

  const serviceAccount = JSON.parse(SERVICE_ACCOUNT_JSON)
  
  // Create JWT for OAuth 2.0
  const privateKey = await importPKCS8(serviceAccount.private_key, 'RS256')
  
  const jwt = await new SignJWT({
    iss: serviceAccount.client_email,
    scope: 'https://www.googleapis.com/auth/firebase.messaging',
    aud: 'https://oauth2.googleapis.com/token',
  })
    .setProtectedHeader({ alg: 'RS256' })
    .setIssuedAt()
    .setExpirationTime('1h')
    .setIssuer(serviceAccount.client_email)
    .sign(privateKey)

  // Exchange JWT for access token
  const response = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
      assertion: jwt,
    }).toString(),
  })

  if (!response.ok) {
    const errorText = await response.text()
    throw new Error(`Failed to get OAuth token: ${response.status} ${errorText}`)
  }

  const tokenData = await response.json() as { access_token?: string }
  
  if (!tokenData.access_token) {
    throw new Error('No access token in response: ' + JSON.stringify(tokenData))
  }

  return tokenData.access_token
}

async function sendFCMNotificationsV1(
  accessToken: string,
  tokens: string[],
  title: string,
  body: string,
  data?: Record<string, any>
): Promise<{ successCount: number; failureCount: number }> {
  if (!PROJECT_ID) {
    throw new Error('FCM_PROJECT_ID secret not configured')
  }

  const FCM_URL = `https://fcm.googleapis.com/v1/projects/${PROJECT_ID}/messages:send`
  
  let successCount = 0
  let failureCount = 0

  // FCM API v1 requires individual requests per token
  for (const token of tokens) {
    const message = {
      message: {
        token: token,
        notification: {
          title: title,
          body: body,
        },
        data: data ? Object.fromEntries(
          Object.entries(data).map(([k, v]) => [k, String(v)])
        ) : {},
        android: {
          priority: 'high' as const,
        },
        apns: {
          headers: {
            'apns-priority': '10',
          },
        },
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
        console.error(`FCM send error for token ${token.substring(0, 20)}...:`, error)
        failureCount++
      }
    } catch (error) {
      console.error('FCM send error:', error)
      failureCount++
    }
  }

  return { successCount, failureCount }
}
