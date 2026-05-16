# Daily Session Management Design Spec (Buka / Tutup Toko)

## Overview
This feature introduces a strict daily session workflow ("Buka Toko" and "Tutup Toko") to the POS system. The system will prevent users from taking orders unless an active session is started. It will track the starting cash, validate the stock, and upon closing the session, perform a cash reconciliation (expected vs actual), show a payment method breakdown, and allow sending a WhatsApp report.

## Architecture & Data Flow

### 1. Database Schema
A new database migration will create a `sessions` table:
- `id` (INTEGER PRIMARY KEY)
- `startTime` (INTEGER)
- `endTime` (INTEGER NULL)
- `startCash` (REAL)
- `expectedCash` (REAL)
- `actualCash` (REAL NULL)
- `cashierName` (TEXT)
- `status` (INTEGER: 0 = active, 1 = closed)

The existing `order_records` table will be modified to include:
- `sessionId` (INTEGER NULL) - Ties the order to the current active session.
- `paymentMethod` (TEXT DEFAULT 'Tunai') - Tracks how the order was paid (Tunai, QRIS, Kartu).

### 2. State Management (Provider)
A new `SessionManager` provider will manage the current session state.
- `bool get hasActiveSession`
- `Future<void> startSession(...)`
- `Future<void> closeSession(...)`
- Subscribes to `Database.instance` and updates the UI accordingly.

### 3. "Buka Toko" (Open Store) Screen
- **Trigger:** Replaces or covers the `OrderPage` body when `hasActiveSession` is false.
- **Inputs:**
  - Starting cash (Modal Kas Awal)
  - Cashier selection (Dropdown of registered users/names, or text input)
- **Validation:** 
  - Iterates through `Stock.instance.items` or menu products to check for low stock (e.g. `amount < warningLevel`).
  - Highlights low stock items in red.
- **Action:** Starts the session and unlocks the `OrderPage`.

### 4. Checkout Modifications
- Add a new "Payment Method" selection step (Tunai / QRIS / Kartu) during checkout.
- Link the completed order to the active `sessionId`.

### 5. "Tutup Toko" (Close Store) Screen
- **Trigger:** Accessible via the "More" / Admin menu, or a persistent "Close Session" button.
- **Calculations:**
  - *Expected Cash* = Starting Cash + (Total Sales where Payment Method == 'Tunai').
  - *Discrepancy (Selisih)* = Actual Inputted Cash - Expected Cash. Highlighted in red if negative.
  - Payment Method Breakdown: Aggregates total sales by `paymentMethod`.
- **Actions:**
  - **Kirim Laporan:** Uses `url_launcher` to construct a WhatsApp deep link containing a formatted text summary of the session.
  - **Tutup Toko:** Updates the session `status` to 1 (closed), saves the `actualCash` and `endTime`, and resets the app state back to the "Buka Toko" screen.

## UI/UX Considerations
- **Material 3 Design:** Forms, Cards, and Inputs will follow the provided sleek aesthetic (rounded corners, distinct color coding for discrepancies).
- **Animations:** Smooth transition from the Buka Toko screen into the main ordering interface.

## Error Handling
- Prevent closing a session without inputting the `actualCash`.
- Ensure database transaction safety when closing a session and writing the summary.
- Handle WhatsApp `url_launcher` failures gracefully (e.g., if WhatsApp is not installed).
