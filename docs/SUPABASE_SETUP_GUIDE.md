# Supabase Configuration Guide

This guide details the exact steps to configure Authentication in your Supabase Dashboard to support your Flutter app (`com.smodekurti.myfamily`).

## 1. URL Configuration

Go to **Authentication** > **URL Configuration**.

1.  **Site URL**: Set this to your project's default URL (e.g., `https://<project-ref>.supabase.co`).
2.  **Redirect URLs**: Add the following URLs individually:
    *   `com.smodekurti.myfamily://home/callback`
    *   `com.smodekurti.myfamily://auth-callback`
    *   `https://<project-ref>.supabase.co/auth/v1/callback` (Required for Apple web flow compatibility)

> **Note**: The custom scheme `com.smodekurti.myfamily` allows the app to reopen after a successful login.

---

## 2. Google Provider Setup

Go to **Authentication** > **Providers** > **Google**.

1.  **Enable Sign in with Google**: Toggle **ON**.
2.  **Authorized Client IDs**:
    *   This is a comma-separated list. You must add **both** your iOS and Android Client IDs.
    *   **iOS ID**: Copy from `ios/Runner/GoogleService-Info.plist` (Look for `CLIENT_ID`).
        *   Example: `985416533716-mtpld73i54069vp2bv91333js1p3cc1d.apps.googleusercontent.com`
    *   **Android ID**: Copy from `android/app/google-services.json` (Look for `client_id` with `client_type: 1`).
        *   Example: `985416533716-gpc5mdmf90vomnviihekkqnijamgecfj.apps.googleusercontent.com`
    *   **Web ID**: (Optional) You might see a web client ID already there; keep it.
3.  **Skip "iOS Bundle ID"**: Leave this field empty or ignore it. Google uses the Client IDs above.
4.  **Save**.

---

## 3. Apple Provider Setup

Go to **Authentication** > **Providers** > **Apple**.

1.  **Enable Sign in with Apple**: Toggle **ON**.
2.  **Client IDs** (previously "Services ID"):
    *   **Input**: `com.smodekurti.myfamily`
    *   *Note*: This acts as the whitelist. Token issued to your iOS app will have an audience of `com.smodekurti.myfamily`.
3.  **Secret Key**:
    *   **Input**: Copy the **entire contents** of your `.p8` file.
4.  **Key ID** / **Team ID**:
    *   Enter your 10-character Key ID and Team ID in the respective fields.
5.  **Save**.

---

## 4. Storage Usage (Verification)

Go to **Storage** > **Buckets**.

1.  Ensure you have a **private** bucket named `user-content`.
2.  Policies should be set to allow authenticated users to upload and read their own files. (This was handled by the `master_db_setup.sql` script).
