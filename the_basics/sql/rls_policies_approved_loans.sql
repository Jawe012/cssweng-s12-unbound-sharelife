-- RLS Policies for approved_loans table
-- 
-- These policies ensure that:
-- 1. Members can read their own approved loans (filtered by member_email)
-- 2. Staff/Encoders can read all approved loans (to encode payments)
-- 3. Only authorized staff can insert/update/delete

-- Enable RLS on approved_loans table
ALTER TABLE public.approved_loans ENABLE ROW LEVEL SECURITY;

-- Policy 1: Allow members to read their own approved loans
-- Members can see loans where member_email matches their auth email
CREATE POLICY "Members can read own approved loans" ON public.approved_loans
  FOR SELECT 
  USING (
    auth.role() = 'authenticated' AND 
    member_email = auth.email()
  );

-- Policy 2: Allow staff/encoders to read ALL approved loans
-- This allows encoders to look up member loans when creating payments
-- Adjust this if you have a specific is_staff() or is_encoder() function
CREATE POLICY "Staff can read all approved loans" ON public.approved_loans
  FOR SELECT 
  USING (
    auth.role() = 'authenticated' AND 
    EXISTS (
      SELECT 1 FROM public.staff 
      WHERE email_address = auth.email()
    )
  );

-- Policy 3: Allow service role full access (for admin operations)
CREATE POLICY "Service role has full access to approved loans" ON public.approved_loans
  FOR ALL 
  USING (auth.role() = 'service_role')
  WITH CHECK (auth.role() = 'service_role');

-- Policy 4: Allow authorized staff to insert approved loans (for loan approval process)
-- This is used when admins approve a loan application
CREATE POLICY "Staff can insert approved loans" ON public.approved_loans
  FOR INSERT 
  WITH CHECK (
    auth.role() = 'authenticated' AND 
    EXISTS (
      SELECT 1 FROM public.staff 
      WHERE email_address = auth.email()
    )
  );

-- Policy 5: Allow authorized staff to update approved loans (for status changes)
CREATE POLICY "Staff can update approved loans" ON public.approved_loans
  FOR UPDATE 
  USING (
    auth.role() = 'authenticated' AND 
    EXISTS (
      SELECT 1 FROM public.staff 
      WHERE email_address = auth.email()
    )
  )
  WITH CHECK (
    auth.role() = 'authenticated' AND 
    EXISTS (
      SELECT 1 FROM public.staff 
      WHERE email_address = auth.email()
    )
  );

-- IMPORTANT: Run this SQL in your Supabase SQL Editor
-- After running, encoders (staff) will be able to read approved_loans for any member
-- and the encoder payment form will work correctly.
