// Unified Supabase Edge Function for Push Notifications
// Handles both DB Webhooks (Chat) and Direct API Calls (Tasks/etc)

import { createClient } from 'jsr:@supabase/supabase-js@2';
import { JWT } from 'npm:google-auth-library@9';

const supabase = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
);

// @ts-ignore
declare const Deno: any;

Deno.serve(async (req: Request) => {
    try {
        const payload = await req.json();

        // DETECT MODE: Webhook vs Direct Call
        const isWebhook = payload.type === 'INSERT' && payload.table === 'messages' && payload.record;

        let userIds: string[] = [];
        let title = '';
        let bodyContent = '';
        let dataPayload = {};

        if (isWebhook) {
            // --- CHAT WEBHOOK MODE ---
            console.log('Processing Chat Webhook:', payload.record.id);
            const record = payload.record;
            bodyContent = record.content;
            dataPayload = { type: 'chat', channel_id: record.channel_id, channel_type: record.channel_type };

            // 1. Identify Recipients
            if (record.channel_type === 'dm') {
                const parts = record.channel_id.split('_');
                if (parts.length === 3) {
                    const uid1 = parts[1];
                    const uid2 = parts[2];
                    if (uid1 !== record.sender_id) userIds.push(uid1);
                    if (uid2 !== record.sender_id) userIds.push(uid2);
                }
            } else if (record.channel_type === 'family') {
                const { data: members } = await supabase
                    .from('family_members')
                    .select('user_id')
                    .eq('family_id', record.family_id)
                    .neq('user_id', record.sender_id);
                if (members) userIds = members.map(m => m.user_id);
            }

            // 2. Determine Title & Body
            // Fetch Family Name if applicable
            let familyName = '';
            if (record.family_id) {
                const { data: family, error: familyError } = await supabase
                    .from('families')
                    .select('name')
                    .eq('id', record.family_id)
                    .single();

                if (familyError) {
                    console.error('Error fetching family:', familyError);
                }

                if (family) {
                    familyName = family.name;
                    console.log('Fetched Family Name:', familyName);
                } else {
                    console.log('Family not found for ID:', record.family_id);
                }
            } else {
                console.log('No family_id in record');
            }

            // Fetch Sender Name
            let senderName = 'Someone';

            // Try family_members first (for nicknames)
            if (record.family_id) {
                const { data: member } = await supabase
                    .from('family_members')
                    .select('display_name')
                    .eq('user_id', record.sender_id)
                    .eq('family_id', record.family_id)
                    .maybeSingle();
                if (member && member.display_name) senderName = member.display_name;
            }

            // Fallback to users table if name is still generic or not found
            if (senderName === 'Someone') {
                const { data: user } = await supabase
                    .from('users')
                    .select('display_name')
                    .eq('id', record.sender_id)
                    .single();
                if (user && user.display_name) senderName = user.display_name;
            }

            // Construct Title - Include Family Name for context in all message types
            if (familyName) {
                title = `[${familyName}] ${senderName}`;
            } else {
                title = senderName;
            }

        } else {
            // --- LEGACY DIRECT CALL MODE ---
            // Payload expected: { user_ids: [], title: '', body: '', data: {} }
            // or { user_id: '...', ... }
            console.log('Processing Direct API Call');

            userIds = payload.user_ids || (payload.user_id ? [payload.user_id] : []);
            title = payload.title || 'Notification';
            bodyContent = payload.body || '';
            dataPayload = payload.data || {};
        }

        if (userIds.length === 0) {
            return new Response(JSON.stringify({ message: 'No recipients' }), { headers: { 'Content-Type': 'application/json' } });
        }

        // --- COMMON: SEND TO FCM ---

        // Fetch tokens from 'user_fcm_tokens'
        const { data: devices } = await supabase
            .from('user_fcm_tokens')
            .select('token')
            .in('user_id', userIds);

        if (!devices || devices.length === 0) {
            return new Response(JSON.stringify({ message: 'No devices found', count: 0 }), { headers: { 'Content-Type': 'application/json' } });
        }

        const uniqueTokens = [...new Set(devices.map(d => d.token))];
        console.log(`Sending to ${uniqueTokens.length} devices...`);

        // Truncate body for notification display
        const displayBody = bodyContent.length > 100 ? bodyContent.substring(0, 97) + '...' : bodyContent;

        const promises = uniqueTokens.map(token => sendFcmMessage(token, title, displayBody, dataPayload));
        await Promise.allSettled(promises);

        return new Response(
            JSON.stringify({ success: true, count: uniqueTokens.length }),
            { headers: { 'Content-Type': 'application/json' } }
        );

    } catch (error: any) {
        console.error('Error processing request:', error);
        return new Response(JSON.stringify({ error: error.message }), { status: 500, headers: { 'Content-Type': 'application/json' } });
    }
});

async function sendFcmMessage(token: string, title: string, body: string, data: Record<string, any>) {
    const serviceAccountJson = Deno.env.get('FIREBASE_SERVICE_ACCOUNT_JSON');
    if (!serviceAccountJson) {
        console.error('Missing secret: FIREBASE_SERVICE_ACCOUNT_JSON');
        return;
    }

    const serviceAccount = JSON.parse(serviceAccountJson);
    const jwtClient = new JWT({
        email: serviceAccount.client_email,
        key: serviceAccount.private_key,
        scopes: ['https://www.googleapis.com/auth/firebase.messaging'],
    });

    const accessToken = await jwtClient.getAccessToken();
    const projectId = serviceAccount.project_id;

    // Ensure all data values are strings
    const stringData = Object.fromEntries(
        Object.entries(data).map(([k, v]) => [k, String(v)])
    );

    const response = await fetch(`https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${accessToken.token}`,
        },
        body: JSON.stringify({
            message: {
                token: token,
                notification: {
                    title: title,
                    body: body,
                },
                data: {
                    click_action: 'FLUTTER_NOTIFICATION_CLICK',
                    ...stringData
                }
            }
        })
    });

    if (!response.ok) {
        console.error(`FCM error for ${token.substring(0, 5)}:`, await response.text());
    }
}
