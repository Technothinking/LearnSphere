# Implementation Plan - Supabase Auth & Persistent Session

## Goal
Implement full Supabase authentication with session persistence. Ensure returning users skip the setup/onboarding flow and go directly to the Dashboard, while new users are guided through signup and setup.

## User Review Required
> [!IMPORTANT]
> I will assume `OnboardingScreen` is the "Landing Page" for unauthenticated users.
> I will change the request to `check-diagnostic` to determine if a user has "finished setup".

## Proposed Changes

### Frontend Integration

#### [NEW] `lib/auth_gate.dart`
- Create a widget `AuthGate` that listens to `Supabase.instance.client.auth.onAuthStateChange`.
- **State: Authenticated**
    - Trigger a Future to `ApiService.getDiagnosticStatus()`.
    - If `check-diagnostic` returns `needs_diagnostic: false` (implied setup done) -> Navigate to `DashboardScreen`.
    - If `check-diagnostic` returns `needs_diagnostic: true` (or new user) -> Navigate to `CreativeSetupAfterLoginV2`.
- **State: Unauthenticated**
    - Show `OnboardingScreen`.

#### [MODIFY] `lib/main.dart`
- Change `home` to `const AuthGate()`.

#### [MODIFY] `lib/screens/login_screen.dart`
- Update `_onLogin` success logic:
    - Replace the hardcoded navigation with `Navigator.pushAndRemoveUntil(..., (route) => false)`.
    - Navigating to `AuthGate` refreshes the state check.

#### [MODIFY] `lib/screens/signup_screen.dart`
- SignUp success can continue to direct to `CreativeSetupAfterLoginV2` (as explicit optimization) or rely on `AuthGate`. Explicit is better for UX flow preservation.

#### [MODIFY] `lib/screens/setup_after_login.dart`
- Ensure that submitting the profile calls an API that updates the `student_permissions` (or whatever flag logic) so `check-diagnostic` subsequently returns "done".

## Verification Plan

### Manual Verification
1.  **Fresh Install**:
    - Launch App -> Expect `OnboardingScreen`.
2.  **Sign Up**:
    - Click "Get Started" -> Sign Up.
    - Enter details -> Expect `CreativeSetupAfterLoginV2`.
    - Complete Setup -> Expect `DashboardScreen`.
3.  **Restart App (Simulation)**:
    - Hot Restart / Re-run -> Expect auto-navigation to `AuthGate` -> `DashboardScreen`.
4.  **Logout**:
    - Call `AuthService.signOut()` (need to ensure a button exists in Profile).
    - Expect `OnboardingScreen`.
5.  **Login (Existing User)**:
    - Login -> Expect `DashboardScreen` (skipping setup).
