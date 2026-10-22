# Flutter mobile app starter notes

The mobile app should share the same Supabase backend and authorization model as the web app. Recommended first screens:

1. Sign in / create account / password reset.
2. Role-aware home screen (landlord/caretaker vs tenant).
3. Properties and units.
4. Tenant profile and tenancy.
5. Bills, payment entry, account statement, receipt preview.
6. Meter reading capture, optional photo attachment, offline draft queue.
7. Bluetooth/network printer service behind a platform-specific adapter.

Before coding printer support, select and test target printer models. Bluetooth Classic, BLE, network, and browser printing have different platform/device constraints. Keep all privileged secrets out of the app. The mobile client must rely on backend authorization and RLS, not role flags stored locally.

Create the Flutter shell with `flutter create jds_keyhold_mobile` on a machine with Flutter installed, then add Supabase Flutter and routing/state dependencies. This initial bundle intentionally does not claim to contain a fully built or device-tested Flutter app yet.
