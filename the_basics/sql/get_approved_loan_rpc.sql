-- SECURITY DEFINER function to return the active approved_loan for a given member_id
-- Run this in Supabase SQL editor as a DB admin/service role.
-- After creating this function you can call it from client via RPC: rpc('get_approved_loan_for_member', {p_member_id: <memberId>})

create or replace function public.get_approved_loan_for_member(p_member_id bigint)
returns table(
  application_id bigint,
  repayment_term text,
  loan_amount numeric,
  status text,
  member_id bigint
)
language sql
security definer
as $$
  select application_id, repayment_term, loan_amount, status, member_id
  from public.approved_loans
  where member_id = p_member_id
    and status = 'active'
  limit 1;
$$;

-- Grant execute to authenticated role if you want authenticated users to call it:
-- grant execute on function public.get_approved_loan_for_member(bigint) to authenticated;

-- IMPORTANT: Because this function is SECURITY DEFINER it runs with the owner's privileges
-- and will bypass RLS for the approved_loans table. Only create this function if you trust
-- the callers and have appropriately restricted access. Alternatively, create a more
-- granular function or add explicit RLS policies to allow staff roles to read approved_loans.
