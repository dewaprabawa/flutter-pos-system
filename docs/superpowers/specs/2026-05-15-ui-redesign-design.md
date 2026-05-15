# Design Doc: UI/UX Modernization

**Date**: 2026-05-15
**Topic**: UI Redesign for Improved Navigation and Discoverability

## 1. Purpose
The current UI hides the core "Order" functionality behind a Floating Action Button and places "Settings" deep within a sub-menu. This design aims to bring these critical functions to the forefront for a faster, more intuitive experience.

## 2. Success Criteria
- Users can start an order in one tap from the home screen.
- Settings are reachable from any main screen with one tap.
- Reduced visual clutter by removing redundant buttons.

## 3. Proposed Architecture

### 3.1 Navigation
- **Primary Menu**: `Order | Analysis | Stock | Cashier | More`
- **Default Page**: The app will now open directly to the **Order** page.
- **Settings**: Moved to the top-right of the **AppBar**.

### 3.2 Routing
The `GoRouter` configuration in `lib/routes.dart` will be updated to include `Order` as a stateful branch in the main shell navigation.

## 4. Components

### 4.1 Home Page (`lib/ui/home/home_page.dart`)
- **_Tab.order**: New enum value with `Icons.shopping_cart`.
- **AppBar Actions**: Added to `_WithTab`, `_WithDrawer`, and `_WithRail`.
- **FAB**: Deprecated and removed.

### 4.2 Routes (`lib/routes.dart`)
- **StatefulShellBranch**: New branch for `_orderRoute`.
- **Redirects**: Updated to handle the new first-tab logic.

## 5. Alternatives Considered
- **Keep FAB**: Rejected because it overlaps content and feels less "native" than a tab-based navigation for core features.
- **Settings as a Tab**: Rejected to keep the bottom navigation focused on operational tasks (Order, Stock, Cashier).

## 6. Testing Plan
- Manual testing of navigation shell transitions.
- Verify persistence of tab state when switching between Order and Analysis.
- Verify "Settings" route works from all main tabs.
