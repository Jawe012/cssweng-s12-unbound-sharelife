# Supabase Storage RLS Configuration for Payment Receipts

## Current Issue
**Error:** `StorageException: new row violates row-level security policy, statusCode: 403, error: Unauthorized`

**Cause:** RLS policies on the `payment_receipts` bucket are blocking uploads because the file path doesn't match the authenticated user's UUID.

---

## ✅ Solution: Updated File Upload Structure

### New Path Convention
Files are now uploaded with user-specific folder structure:

```
USER_UUID/receipts/TIMESTAMP_sanitizedfilename.ext
```

**Example paths:**
```
a1b2c3d4-5678-90ab-cdef-1234567890ab/receipts/1730908800000_gcash_payment_screenshot.png
a1b2c3d4-5678-90ab-cdef-1234567890ab/receipts/1730908900000_receipt_2025-11-06.jpg
```

### Benefits
- ✅ Each user can only access their own files
- ✅ Prevents file name collisions between users
- ✅ Organized by user and category (receipts)
- ✅ Timestamp ensures uniqueness
- ✅ Sanitized filenames prevent security issues

---

## 🔧 Required Supabase Configuration

### Step 1: Update Storage Bucket RLS Policies

Go to **Supabase Dashboard** → **Storage** → **payment_receipts** → **Policies**

#### Policy 1: Allow users to INSERT their own files

```sql
-- Policy Name: Users can upload to their own folder
CREATE POLICY "Users can upload to own folder"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'payment_receipts' 
  AND (storage.foldername(name))[1] = auth.uid()::text
);
```

**Explanation:**
- `bucket_id = 'payment_receipts'` - Only applies to this bucket
- `(storage.foldername(name))[1]` - Extracts the first folder in the path (the UUID)
- `auth.uid()::text` - The authenticated user's UUID
- Users can ONLY upload files to `USER_UUID/...` where UUID matches their own

#### Policy 2: Allow users to SELECT their own files

```sql
-- Policy Name: Users can read their own files
CREATE POLICY "Users can read own files"
ON storage.objects FOR SELECT
TO authenticated
USING (
  bucket_id = 'payment_receipts' 
  AND (storage.foldername(name))[1] = auth.uid()::text
);
```

#### Policy 3: Allow users to UPDATE their own files (optional)

```sql
-- Policy Name: Users can update their own files
CREATE POLICY "Users can update own files"
ON storage.objects FOR UPDATE
TO authenticated
USING (
  bucket_id = 'payment_receipts' 
  AND (storage.foldername(name))[1] = auth.uid()::text
)
WITH CHECK (
  bucket_id = 'payment_receipts' 
  AND (storage.foldername(name))[1] = auth.uid()::text
);
```

#### Policy 4: Allow users to DELETE their own files (optional)

```sql
-- Policy Name: Users can delete their own files
CREATE POLICY "Users can delete own files"
ON storage.objects FOR DELETE
TO authenticated
USING (
  bucket_id = 'payment_receipts' 
  AND (storage.foldername(name))[1] = auth.uid()::text
);
```

---

### Step 2: Staff/Admin Access (Optional)

If staff/encoders need to access all payment receipts:

```sql
-- Policy Name: Staff can read all payment receipts
CREATE POLICY "Staff can read all receipts"
ON storage.objects FOR SELECT
TO authenticated
USING (
  bucket_id = 'payment_receipts'
  AND EXISTS (
    SELECT 1 FROM staff 
    WHERE staff.email_address = auth.email()
  )
);
```

---

## 📝 Code Changes Made

### Member Payment Form (`mem_payment.dart`)
```dart
// OLD: Simple filename (violates RLS)
final fileName = 'gcash_${timestamp}_${file.name}';

// NEW: User-specific path with sanitization
final userId = Supabase.instance.client.auth.currentUser?.id;
String sanitizedFilename = file.name
    .toLowerCase()
    .replaceAll(' ', '_')
    .replaceAll(RegExp(r'[^a-z0-9._-]'), '');
final timestamp = DateTime.now().millisecondsSinceEpoch;
final filePath = '$userId/receipts/${timestamp}_$sanitizedFilename';
```

### Encoder Payment Form (`encoder_payment.dart`)
Same changes applied for consistency.

---

## 🧪 Testing the Fix

### Test 1: Check RLS Policies
1. Go to Supabase Dashboard → Storage → payment_receipts
2. Click "Policies" tab
3. Verify you have the policies listed above
4. Make sure they're **enabled** (green toggle)

### Test 2: Upload Test
1. Login as a member or encoder
2. Go to Payment form
3. Select GCash payment method
4. Upload a screenshot
5. Submit payment

**Expected Console Output:**
```
[MemberPayment] Uploading receipt to: a1b2c3d4-5678.../receipts/1730908800000_screenshot.png
[MemberPayment] ✓ File uploaded successfully
[MemberPayment] Public URL: https://...
```

**Expected Result:**
- ✅ File uploads successfully
- ✅ No 403 error
- ✅ File appears in storage under `USER_UUID/receipts/`

### Test 3: Verify File Structure
1. Go to Supabase Dashboard → Storage → payment_receipts
2. You should see folders with UUID names
3. Inside each UUID folder → `receipts/` → uploaded files

---

## 🔍 Troubleshooting

### Still getting 403 Unauthorized?

**Check 1: Authentication**
```dart
final user = Supabase.instance.client.auth.currentUser;
print('User ID: ${user?.id}');
print('User Email: ${user?.email}');
```
If `null`, user is not authenticated.

**Check 2: Bucket Name**
Ensure bucket is exactly `payment_receipts` (case-sensitive).

**Check 3: Path Format**
```dart
print('Upload path: $filePath');
// Should print: "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx/receipts/12345678_file.png"
```

**Check 4: RLS Policy**
Run this SQL to test policy:
```sql
SELECT 
  name,
  (storage.foldername(name))[1] as first_folder,
  auth.uid()::text as current_user
FROM storage.objects
WHERE bucket_id = 'payment_receipts';
```

**Check 5: Re-create Policies**
If policies aren't working:
1. Delete all existing policies on `payment_receipts` bucket
2. Re-create using the SQL above
3. Make sure to enable them

---

## 📊 Database Table for File Metadata (Optional)

To track uploaded files, create this table:

```sql
CREATE TABLE payment_receipt_files (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id),
  bucket TEXT NOT NULL DEFAULT 'payment_receipts',
  file_path TEXT NOT NULL,
  original_filename TEXT NOT NULL,
  file_size BIGINT,
  mime_type TEXT,
  uploaded_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  payment_id BIGINT REFERENCES payments(payment_id),
  
  CONSTRAINT unique_file_path UNIQUE(bucket, file_path)
);

-- RLS: Users can only see their own files
ALTER TABLE payment_receipt_files ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read own receipt files"
ON payment_receipt_files FOR SELECT
TO authenticated
USING (user_id = auth.uid());

CREATE POLICY "Users can insert own receipt files"
ON payment_receipt_files FOR INSERT
TO authenticated
WITH CHECK (user_id = auth.uid());
```

Then in your code, after successful upload:
```dart
await Supabase.instance.client
  .from('payment_receipt_files')
  .insert({
    'user_id': userId,
    'file_path': filePath,
    'original_filename': proofOfPaymentFile!.name,
    'file_size': bytes.length,
    'mime_type': 'image/${sanitizedFilename.split('.').last}',
  });
```

---

## ✅ Summary

**What Changed:**
1. ✅ Upload path now includes user UUID: `USER_UUID/receipts/TIMESTAMP_file.ext`
2. ✅ Filenames are sanitized (lowercase, no spaces, no special chars)
3. ✅ Timestamps prevent collisions
4. ✅ Better error logging for debugging

**What You Need to Do:**
1. ✅ Update Supabase RLS policies (SQL above)
2. ✅ Test file upload
3. ✅ Verify files appear in correct user folders
4. ✅ (Optional) Create file metadata table

**Expected Result:**
- 🎉 No more 403 errors
- 🎉 Files upload successfully
- 🎉 Each user can only access their own files
- 🎉 Organized folder structure
