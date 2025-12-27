-- ============================================================================
-- FIND FAMILY BY INVITE CODE (RPC)
-- ============================================================================
-- This script creates a secure function to look up families by invite code.
-- It bypasses RLS (SECURITY DEFINER) but only returns the specific family
-- matching the secret code, which is safe for this use case.
-- ============================================================================

CREATE OR REPLACE FUNCTION find_family_by_invite_code(invite_code_param TEXT)
RETURNS SETOF families
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  RETURN QUERY
  SELECT *
  FROM families
  WHERE invite_code = invite_code_param
     OR parent_invite_code = invite_code_param
     OR child_invite_code = invite_code_param
  LIMIT 1;
END;
$$;

-- Grant execution permission to authenticated users (and anon if needed for signup)
GRANT EXECUTE ON FUNCTION find_family_by_invite_code(TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION find_family_by_invite_code(TEXT) TO anon;
