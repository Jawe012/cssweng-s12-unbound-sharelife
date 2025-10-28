-- Ensure RLS enabled
ALTER TABLE public.loan_application ENABLE ROW LEVEL SECURITY;

-- Super-admin: full access
CREATE POLICY loan_app_super_admin_all ON public.loan_application
  FOR ALL
  TO authenticated
  USING (public.is_super_admin() = TRUE)
  WITH CHECK (public.is_super_admin() = TRUE);

-- Member: read own applications
CREATE POLICY loan_app_member_select ON public.loan_application
  FOR SELECT
  TO authenticated
  USING (member_id = public.current_member_id());

-- Member: insert new application for self
CREATE POLICY loan_app_member_insert ON public.loan_application
  FOR INSERT
  TO authenticated
  WITH CHECK (member_id = public.current_member_id());

-- Approver staff: can read all
CREATE POLICY loan_app_approver_select ON public.loan_application
  FOR SELECT
  TO authenticated
  USING (public.is_approver() = TRUE);

-- Approver staff: can update (approve/reject)
CREATE POLICY loan_app_approver_update ON public.loan_application
  FOR UPDATE
  TO authenticated
  USING (public.is_approver() = TRUE)
  WITH CHECK (public.is_approver() = TRUE);