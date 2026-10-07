# Supabase Setup Guide

This project is configured to use Supabase as its cloud backend.

A complete, production-ready SQL script is maintained in [`schema.sql`](./schema.sql).

---

## Fresh Setup Instructions

1. Log into your **Supabase Dashboard**.
2. Open the **SQL Editor** tab.
3. Open [`schema.sql`](./schema.sql) in this repository and copy all its contents.
4. Paste into the SQL Editor and click **Run**.

---

## Core Schema Summary

The schema includes the following tables fully synced with the Flutter application models (`lib/models/`):

1. **`branches`** - Store locations & registrations.
2. **`users`** - User accounts, staff PIN passcodes (`passcode`, `is_passcode_enabled`), temporary promotions, permissions, and salary stats.
3. **`products`** - Inventory master list, pricing brackets, promotions (`promo_start`, `promo_end`), and low stock thresholds.
4. **`sales`** - Sales transactions, item lists, multi-payment details, discount calculations, and bank receipt verifications.
5. **`animals`** - Intake tracking for livestock/farm supplies.
6. **`slaughter_logs`** - Processing intake, live vs meat weights, quantity batches, and staff attribution (`slaughtered_by`, `portioned_by`).
7. **`meat_batches`** - Warehouse batches, cost & retail prices, expiry tracking (`expiry_date`), shelf locations, and barcodes.
8. **`meat_cuts`** - Portioned unit stock items linked to batches.
9. **`butcher_waste`** - Waste/loss logging for inventory reconciliation.
10. **`butcher_orders`** - Custom order management for customers.
11. **`stock_transfers`** - Internal and 3rd-party stock transfers between locations.
12. **`expenses`** - Operating expense records and receipt uploads.
13. **`customers`** - CRM records, contact numbers (`phone`, `phone2`), wholesaler/bulk flags, loyalty points, and custom discounts.
14. **`staff_payments_audit`** - Payroll history logs (`target_month`, advance flags, note).
15. **`customer_payments`** - Debt settlements and partial payment tracking.
16. **`stock_history`** - Inventory ledger tracking stock changes over time.
17. **`audit_logs`** - System action audit trails for compliance.
18. **`notifications`** - Push and system alerts per user/branch.
19. **`documentss`** - Document metadata and file attachments.

---

## RPC Functions

* **`increment_stock(p_id UUID, p_amount NUMERIC)`**: Atomic update function for stock adjustments to handle high-concurrency offline sync operations safely.
