# Implementation Plan: Daily Session Management

## Phase 1: Database & Data Models
- [ ] Increment `latestVersion` in `lib/services/database.dart` to 13.
- [ ] Add migration script to create the `sessions` table and alter `order_records` to include `sessionId` and `paymentMethod`.
- [ ] Create `lib/models/session.dart` to define the `Session` entity.
- [ ] Create `lib/models/repository/session_manager.dart` to act as a Provider managing the currently active session state.

## Phase 2: Checkout & Payment Tracking
- [ ] Modify `OrderRecordObject` and `OrderRecord` to include `sessionId` and `paymentMethod`.
- [ ] Modify `CheckoutStatus` and the `CheckoutPage` to include a Payment Method selector (Tunai, QRIS, Kartu).
- [ ] Update `Cart.instance.checkout` and `OrderRecords.instance.push` to save the new fields.

## Phase 3: Buka Toko (Open Store) Screen
- [ ] Build the `BukaTokoPage` widget UI per the sleek design specifications.
- [ ] Integrate a quick stock validation using `Stock.instance.items` to list low-stock ingredients or products.
- [ ] Build logic to start the session (validates inputs, inserts into `sessions`, updates `SessionManager`).

## Phase 4: App Integration & Navigation
- [ ] Modify `OrderPage` to conditionally display `BukaTokoPage` if `SessionManager.instance.hasActiveSession` is false.
- [ ] Ensure the main application initializes the `SessionManager` provider during app startup (`lib/main.dart`).

## Phase 5: Tutup Toko (Close Store) Screen
- [ ] Build the `TutupTokoPage` widget UI with Material 3 cards for session summary.
- [ ] Implement the calculation logic for expected cash, total sales, transaction counts, and payment breakdowns.
- [ ] Add the WhatsApp integration using `url_launcher` for "Kirim Laporan".
- [ ] Implement the "Tutup Toko" action to close the session in the DB and reset state.
