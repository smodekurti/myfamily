// Supabase Edge Function to send push notifications via FCM API v1
// Uses Service Account credentials (not deprecated Server Key)
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { SignJWT, importPKCS8 } from 'https://deno.land/x/jose@v4.14.4/index.ts'

const SERVICE_ACCOUNT_JSON = Deno.env.get('FCM_SERVICE_ACCOUNT_JSON')
const PROJECT_ID = Deno.env.get('FCM_PROJECT_ID') || ''

serve(async (req) => {
  try {
    // Check for required secrets early
    if (!SERVICE_ACCOUNT_JSON) {
      console.error('FCM_SERVICE_ACCOUNT_JSON secret is not configured')
      return new Response(
        JSON.stringify({ 
          error: 'FCM_SERVICE_ACCOUNT_JSON secret not configured. See PUSH_NOTIFICATIONS_SETUP_V1.md',
          details: 'The FCM_SERVICE_ACCOUNT_JSON secret must be set in Supabase Dashboard > Edge Functions > Secrets'
        }),
        { status: 500, headers: { 'Content-Type': 'application/json' } }
      )
    }

    if (!PROJECT_ID) {
      console.error('FCM_PROJECT_ID secret is not configured')
      return new Response(
        JSON.stringify({ 
          error: 'FCM_PROJECT_ID secret not configured',
          details: 'The FCM_PROJECT_ID secret must be set in Supabase Dashboard > Edge Functions > Secrets'
        }),
        { status: 500, headers: { 'Content-Type': 'application/json' } }
      )
    }

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

    // Parse request body with error handling
    let requestBody
    try {
      requestBody = await req.json()
    } catch (e) {
      console.error('Error parsing request JSON:', e)
      return new Response(
        JSON.stringify({ error: 'Invalid JSON in request body', details: e instanceof Error ? e.message : 'Unknown error' }),
        { status: 400, headers: { 'Content-Type': 'application/json' } }
      )
    }

    const { user_id, user_ids, title, body, data } = requestBody
    const userIds = user_ids || (user_id ? [user_id] : [])

    if (userIds.length === 0) {
      return new Response(
        JSON.stringify({ error: 'No user IDs provided' }),
        { status: 400, headers: { 'Content-Type': 'application/json' } }
      )
    }

    // Get FCM tokens for all users (include id and device_type for platform-specific messages)
    console.log(`Looking for FCM tokens for user IDs: ${JSON.stringify(userIds)}`)
    const { data: tokens, error } = await supabaseClient
      .from('user_fcm_tokens')
      .select('id, token, device_type')
      .in('user_id', userIds)

    if (error) {
      console.error('Error fetching FCM tokens:', error)
      throw error
    }

    console.log(`Found ${tokens?.length || 0} FCM tokens for ${userIds.length} user(s)`)

    if (!tokens || tokens.length === 0) {
      console.warn(`No FCM tokens found for users: ${JSON.stringify(userIds)}`)
      return new Response(
        JSON.stringify({ 
          message: 'No FCM tokens found for users', 
          sent: 0,
          failed: 0,
          userIds: userIds
        }),
        { status: 200, headers: { 'Content-Type': 'application/json' } }
      )
    }

    // Get OAuth access token
    const accessToken = await getOAuthToken()
    
    // Send notifications via FCM API v1 (include device_type for platform-specific formatting)
    const fcmTokens = tokens.map((t: { token: string; id: string; device_type: string }) => ({ 
      token: t.token, 
      id: t.id,
      deviceType: t.device_type 
    }))
    console.log(`Sending notifications to ${fcmTokens.length} device(s)`)
    const results = await sendFCMNotificationsV1(accessToken, fcmTokens, title, body, data, supabaseClient)

    console.log(`Notification results: ${results.successCount} sent, ${results.failureCount} failed, ${results.invalidTokensRemoved} invalid tokens removed`)

    return new Response(
      JSON.stringify({ 
        message: 'Notifications sent',
        sent: results.successCount,
        failed: results.failureCount,
        invalidTokensRemoved: results.invalidTokensRemoved,
        total: fcmTokens.length
      }),
      { status: 200, headers: { 'Content-Type': 'application/json' } }
    )
  } catch (error: unknown) {
    console.error('Error in send-push-notification function:', error)
    const errorMessage = error instanceof Error ? error.message : 'Unknown error'
    const errorStack = error instanceof Error ? error.stack : undefined
    
    // Log full error details for debugging
    console.error('Error details:', {
      message: errorMessage,
      stack: errorStack,
      type: error?.constructor?.name,
    })
    
    return new Response(
      JSON.stringify({ 
        error: errorMessage,
        details: errorStack ? 'Check Supabase Edge Function logs for full stack trace' : undefined
      }),
      { status: 500, headers: { 'Content-Type': 'application/json' } }
    )
  }
})

async function getOAuthToken(): Promise<string> {
  if (!SERVICE_ACCOUNT_JSON) {
    throw new Error('FCM_SERVICE_ACCOUNT_JSON secret not configured. See PUSH_NOTIFICATIONS_SETUP_V1.md')
  }

  // Clean the JSON string - remove any leading/trailing whitespace or quotes
  let cleanedJson = SERVICE_ACCOUNT_JSON.trim()
  
  // Remove surrounding quotes if present (sometimes happens when copying)
  if ((cleanedJson.startsWith('"') && cleanedJson.endsWith('"')) ||
      (cleanedJson.startsWith("'") && cleanedJson.endsWith("'"))) {
    cleanedJson = cleanedJson.slice(1, -1)
  }
  
  // Remove any leading/trailing whitespace again after removing quotes
  cleanedJson = cleanedJson.trim()

  let serviceAccount
  try {
    serviceAccount = JSON.parse(cleanedJson)
  } catch (e) {
    console.error('Error parsing SERVICE_ACCOUNT_JSON:', e)
    console.error('JSON string length:', cleanedJson.length)
    console.error('First 100 characters:', cleanedJson.substring(0, 100))
    console.error('Last 100 characters:', cleanedJson.substring(Math.max(0, cleanedJson.length - 100)))
    throw new Error(`Invalid FCM_SERVICE_ACCOUNT_JSON format: ${e instanceof Error ? e.message : 'Unknown error'}. Make sure you copied the entire JSON object without extra characters.`)
  }

  // Validate required fields
  if (!serviceAccount.private_key) {
    throw new Error('SERVICE_ACCOUNT_JSON missing private_key field')
  }
  if (!serviceAccount.client_email) {
    throw new Error('SERVICE_ACCOUNT_JSON missing client_email field')
  }
  
  // Create JWT for OAuth 2.0
  let privateKey
  try {
    privateKey = await importPKCS8(serviceAccount.private_key, 'RS256')
  } catch (e) {
    console.error('Error importing private key:', e)
    throw new Error(`Failed to import private key: ${e instanceof Error ? e.message : 'Unknown error'}. Make sure the private_key in SERVICE_ACCOUNT_JSON is a valid PKCS8 format.`)
  }
  
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
  tokens: Array<{ token: string; id: string; deviceType: string }>,
  title: string,
  body: string,
  data: Record<string, any> | undefined,
  supabaseClient: any
): Promise<{ successCount: number; failureCount: number; invalidTokensRemoved: number }> {
  if (!PROJECT_ID) {
    throw new Error('FCM_PROJECT_ID secret not configured')
  }

  const FCM_URL = `https://fcm.googleapis.com/v1/projects/${PROJECT_ID}/messages:send`
  
  let successCount = 0
  let failureCount = 0
  let invalidTokensRemoved = 0

    // FCM API v1 requires individual requests per token
    for (const { token, id, deviceType } of tokens) {
      const isIOS = deviceType === 'ios'
      
      // Base message structure
      const message: any = {
        message: {
          token: token,
          notification: {
            title: title,
            body: body,
          },
          data: data ? Object.fromEntries(
            Object.entries(data).map(([k, v]) => [k, String(v)])
          ) : {},
        },
      }

      // Platform-specific configurations
      if (isIOS) {
        // iOS (APNs) configuration
        // Build APNs payload with aps (Apple's reserved fields) and custom data
        const apnsPayload: any = {
            aps: {
              alert: {
                title: title,
                body: body,
              },
              sound: 'default',
              badge: 1,
          },
        }
        
        // Add custom data fields to APNs payload (at root level, not inside aps)
        if (data) {
          Object.entries(data).forEach(([key, value]) => {
            apnsPayload[key] = String(value)
          })
        }
        
        message.message.apns = {
          headers: {
            'apns-priority': '10',
            'apns-push-type': 'alert',
            },
          payload: apnsPayload,
        }
        console.log(`📱 Sending iOS notification to token ${token.substring(0, 20)}...`)
        console.log(`📱 iOS APNs payload: ${JSON.stringify(apnsPayload)}`)
      } else {
        // Android configuration
        message.message.android = {
          priority: 'high' as const,
          notification: {
            sound: 'default',
            channelId: 'push_notifications',
          },
        }
        console.log(`🤖 Sending Android notification to token ${token.substring(0, 20)}...`)
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
        console.log(`✅ Notification sent successfully to token ${token.substring(0, 20)}...`)
      } else {
        const errorText = await response.text()
        let errorData
        try {
          errorData = JSON.parse(errorText)
        } catch {
          errorData = { error: { message: errorText } }
        }
        
        const errorCode = errorData?.error?.details?.[0]?.errorCode || errorData?.error?.code
        const errorMessage = errorData?.error?.message || errorText
        
        console.error(`❌ FCM send error for token ${token.substring(0, 20)}...:`, errorMessage)
        
        // Check if token is invalid and should be removed
        if (errorCode === 'UNREGISTERED' || errorCode === 'INVALID_ARGUMENT' || 
            errorMessage.includes('UNREGISTERED') || errorMessage.includes('NOT_FOUND')) {
          console.log(`🗑️ Removing invalid token ${token.substring(0, 20)}... from database`)
          try {
            const { error: deleteError } = await supabaseClient
              .from('user_fcm_tokens')
              .delete()
              .eq('id', id)
            
            if (deleteError) {
              console.error(`Failed to delete invalid token:`, deleteError)
            } else {
              invalidTokensRemoved++
              console.log(`✅ Invalid token removed from database`)
            }
          } catch (deleteErr) {
            console.error(`Error deleting invalid token:`, deleteErr)
          }
        }
        
        failureCount++
      }
    } catch (error) {
      console.error('FCM send error:', error)
      failureCount++
    }
  }

  return { successCount, failureCount, invalidTokensRemoved }
}
