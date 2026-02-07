# Task List: Supabase Auth & Navigation

- [ ] **Explore Frontend Auth**: Check `main.dart` and `screens/` for existing login/signup logic.
- [ ] **Create/Update Signup Screen**: Implement `signup_screen.dart` with Supabase `signUp`.
- [ ] **Create/Update Login Screen**: Implement/Verify `login_screen.dart` with Supabase `signIn`.
- [ ] **Implement Auth Gate**: Create a wrapper widget to handle Auth State changes.
- [ ] **Navigation Logic**:
    - [ ] On Launch: Check `Supabase.auth.currentUser`.
    - [ ] If logged in: Call `check-diagnostic` API.
    - [ ] If `needs_diagnostic` is false: Go to Dashboard/Home.
    - [ ] If `needs_diagnostic` is true: Go to Diagnostic/Onboarding.
- [ ] **Backend Verification**: Ensure `perm.completed_chapters` is correctly returned (already done).
