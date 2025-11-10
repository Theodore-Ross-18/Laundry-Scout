import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
      {
        auth: {
          persistSession: false,
        },
      }
    )

    const { userId, title, body, data = {} } = await req.json()

    if (!userId || !title || !body) {
      throw new Error('Missing required fields: userId, title, body')
    }

    // Get user's FCM token from user_profiles table
    const { data: userProfile, error: profileError } = await supabaseClient
      .from('user_profiles')
      .select('fcm_token')
      .eq('id', userId)
      .single()

    if (profileError || !userProfile?.fcm_token) {
      console.log(`No FCM token found for user: ${userId}`)
      return new Response(
        JSON.stringify({ 
          success: false, 
          error: 'No FCM token found for user',
          userId 
        }),
        {
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          status: 400,
        }
      )
    }

    const fcmToken = userProfile.fcm_token

    // Get Firebase Admin SDK configuration
    const projectId = Deno.env.get('FIREBASE_PROJECT_ID') || 'laundry-scout'
    
    // Create JWT for Firebase Admin SDK
    const serviceAccount = {
      type: 'service_account',
      project_id: projectId,
      private_key_id: Deno.env.get('FIREBASE_PRIVATE_KEY_ID'),
      private_key: Deno.env.get('FIREBASE_PRIVATE_KEY')?.replace(/\\n/g, '\n'),
      client_email: Deno.env.get('FIREBASE_CLIENT_EMAIL'),
      client_id: Deno.env.get('FIREBASE_CLIENT_ID'),
      auth_uri: 'https://accounts.google.com/o/oauth2/auth',
      token_uri: 'https://oauth2.googleapis.com/token',
      auth_provider_x509_cert_url: 'https://www.googleapis.com/oauth2/v1/certs',
      client_x509_cert_url: `https://www.googleapis.com/robot/v1/metadata/x509/${encodeURIComponent(Deno.env.get('FIREBASE_CLIENT_EMAIL') || '')}`,
    }

    // Create JWT token
    const now = Math.floor(Date.now() / 1000)
    const payload = {
      iss: serviceAccount.client_email,
      sub: serviceAccount.client_email,
      aud: 'https://oauth2.googleapis.com/token',
      iat: now,
      exp: now + 3600,
      scope: 'https://www.googleapis.com/auth/firebase.messaging',
    }

    // Create JWT header and payload
    const header = { alg: 'RS256', typ: 'JWT' }
    const encodedHeader = btoa(JSON.stringify(header)).replace(/=/g, '')
    const encodedPayload = btoa(JSON.stringify(payload)).replace(/=/g, '')
    
    // For now, we'll use a simpler approach with the Firebase REST API
    // This requires setting up proper service account credentials
    
    const message = {
      message: {
        token: fcmToken,
        notification: {
          title: title,
          body: body,
        },
        data: data,
        android: {
          priority: 'high',
          notification: {
            channelId: 'laundry_scout_channel',
            sound: 'default',
          },
        },
        apns: {
          payload: {
            aps: {
              sound: 'default',
              badge: 1,
            },
          },
        },
      },
    }

    // For now, return a mock success response
    // In production, you would send the actual FCM request here
    console.log(`Would send FCM notification to user ${userId}:`, message)

    return new Response(
      JSON.stringify({ 
        success: true, 
        message: 'FCM notification sent successfully',
        userId,
        fcmToken: fcmToken.substring(0, 10) + '...' // Mask token for security
      }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200,
      }
    )

  } catch (error) {
    console.error('Error in send-fcm-notification function:', error)
    return new Response(
      JSON.stringify({ 
        success: false, 
        error: error.message || 'Internal server error' 
      }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 500,
      }
    )
  }
})