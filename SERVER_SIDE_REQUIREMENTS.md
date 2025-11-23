# Server-Side Requirements and Fixes

## Issues Fixed (Client-Side)

### ✅ Note #33, #40: Repayment Term Enum Mismatch
**Problem**: Form sends "Monthly"/"Bimonthly" but DB rejects these values.

**Client Fix Applied**: Removed `.toLowerCase()` normalization that was converting to "monthly"/"bimonthly".

**SERVER ACTION REQUIRED**:
You need to check what enum values your `loan_term` type actually has. Run this in Supabase SQL Editor:

```sql
SELECT unnest(enum_range(NULL::loan_term));
```

Then choose ONE of these options:

**Option A (Recommended)**: Add the UI values to your enum
```sql
ALTER TYPE loan_term ADD VALUE IF NOT EXISTS 'Monthly';
ALTER TYPE loan_term ADD VALUE IF NOT EXISTS 'Bimonthly';
```

**Option B**: Change UI to match your DB values (if enum has lowercase values)
- If your enum has 'monthly' and 'bimonthly', I can add client-side mapping to lowercase the values before sending.

---

### ✅ Note #36: Payment Totals Include Pending/Invalidated
**Problem**: "Total Paid" included all payment statuses.

**Client Fix Applied**: Modified `mem_payment_history.dart` to only count payments with status = 'Approved' in total calculations.

**No server action needed**.

---

### ✅ Note #37: Staff Phone Number Column Error
**Problem**: Code referenced `phone_number` but schema has `contact_no`.

**Client Fix Applied**: Changed all references from `phone_number` to `contact_no` in `admin_edit_staff.dart`. Also removed `home_address` reference since it doesn't exist in staff table.

**SERVER VERIFICATION**: Confirm your `staff` table has:
- `contact_no` column (varchar)
- Does NOT have `phone_number` or `home_address` columns

---

### ✅ Note #39: Encoder Dashboard Hardcoded Stats
**Problem**: Dashboard showed fake numbers "123", "456", etc.

**Client Fix Applied**: Converted `encoder_dashb.dart` to StatefulWidget with real DB queries:
- Pending Applications: counts `loan_application` where `status = 'Pending'`
- Approved Applications: counts `approved_loans` table
- Total Encoded: counts all `loan_application` entries

**No server action needed**.

---

### ✅ Note #41, #43: members.member_id Column Error
**Problem**: Code queried members table using `.eq('member_id', ...)` but the primary key is `id`.

**Client Fix Applied**: Changed all member lookups to use `.eq('id', memberId)` in:
- `encoder_reports.dart` (3 locations)
- `encoder_loanpay_records.dart`
- `admin_loanpay_records.dart`

**No server action needed**.

---

## Issues Requiring Further Work

### 🟡 Note #34, #35: Contact Support / View Payment Records Buttons
**Status**: Buttons exist but have no functionality.

**Action Needed**: 
- Design what these buttons should do
- Implement navigation/modals for these features
- This is a UI/UX decision, not a server issue

---

### 🟡 Note #38: Remember Me Checkbox
**Status**: Checkbox cannot be ticked.

**Action Needed**: 
- Investigate checkbox state management in register page
- May be a simple setState issue or validation rule blocking it

---

### 🟡 Note #42: GCash Screenshot Bucket Not Found
**Problem**: Error accessing payment receipts: `{"error":"Bucket not found"}`

**SERVER ACTION REQUIRED**:

1. **Create the storage bucket** in Supabase:
   - Go to Storage in Supabase dashboard
   - Create a bucket named `payment_receipts`
   - Make it public or set appropriate RLS policies

2. **Set up RLS policies** for the bucket:

```sql
-- Allow authenticated users to upload their own receipts
CREATE POLICY "Users can upload payment receipts"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'payment_receipts' AND auth.uid()::text = (storage.foldername(name))[1]);

-- Allow staff to read all receipts
CREATE POLICY "Staff can view all payment receipts"
ON storage.objects FOR SELECT
TO authenticated
USING (
  bucket_id = 'payment_receipts' 
  AND EXISTS (
    SELECT 1 FROM public.staff 
    WHERE staff.user_id = auth.uid()
  )
);

-- Allow members to read their own receipts
CREATE POLICY "Members can view their own receipts"
ON storage.objects FOR SELECT
TO authenticated
USING (
  bucket_id = 'payment_receipts' 
  AND auth.uid()::text = (storage.foldername(name))[1]
);
```

3. **Verify existing paths**: Check if any files were uploaded to a different bucket name.

---

### 🟡 Note #44: Payment Records Only Show Amounts
**Status**: Payment list displays only amounts, missing other details.

**Action Needed**:
- Update UI to display additional payment fields (payment type, date, reference numbers, etc.)
- This is a client-side UI enhancement

---

### 🟡 Note #45, #46: Voucher Generation Validation
**Status**: Voucher can be submitted with missing fields; date inputs accept invalid formats.

**Action Needed**:
- Add proper date picker components (DateInputField or similar)
- Add required field validation in voucher form
- Consider adding server-side validation as well for data integrity

**Recommended Server-Side Validation**:
```sql
-- Add constraints to voucher table
ALTER TABLE public.vouchers
  ALTER COLUMN date_issued SET NOT NULL,
  ALTER COLUMN prepared_name SET NOT NULL,
  ALTER COLUMN prepared_date SET NOT NULL;

-- Add CHECK constraints for date fields
ALTER TABLE public.vouchers
  ADD CONSTRAINT valid_dates CHECK (
    prepared_date IS NOT NULL AND
    (checked_date IS NULL OR checked_date >= prepared_date) AND
    (approved_date IS NULL OR approved_date >= prepared_date)
  );
```

---

## Summary of Server-Side Actions

### CRITICAL (Do These First):

1. **Fix `loan_term` enum** (Notes #33, #40):
   ```sql
   -- Check current values
   SELECT unnest(enum_range(NULL::loan_term));
   
   -- Add if missing
   ALTER TYPE loan_term ADD VALUE IF NOT EXISTS 'Monthly';
   ALTER TYPE loan_term ADD VALUE IF NOT EXISTS 'Bimonthly';
   ```

2. **Create `payment_receipts` storage bucket** (Note #42):
   - Create bucket in Supabase Storage
   - Apply RLS policies shown above

### RECOMMENDED:

3. **Verify staff table schema** (Note #37):
   - Confirm `contact_no` column exists
   - Confirm `phone_number` and `home_address` do NOT exist (or update client to use them)

4. **Add voucher validation** (Notes #45, #46):
   - Add NOT NULL constraints to required fields
   - Add CHECK constraints for date logic

---

## Testing Checklist

After applying server changes:

- [ ] Submit loan application with "Monthly" repayment term
- [ ] Submit loan application with "Bimonthly" repayment term
- [ ] Upload GCash payment receipt (verify bucket access)
- [ ] View payment screenshot (verify URL generation)
- [ ] Edit staff member details (verify contact_no saves correctly)
- [ ] Check encoder dashboard shows real counts
- [ ] Verify payment totals only include Approved payments
- [ ] Test voucher submission with missing fields (should fail if constraints added)
