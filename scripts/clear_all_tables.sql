-- ============================================================================
-- DYNAMIC CLEAR ALL DATA SCRIPT
-- ============================================================================
-- This script dynamically finds all existing tables in the public schema
-- and truncates them. This prevents errors if specific tables are missing.
-- It excludes 'consent_content' to preserve Terms/Privacy polices.
--
-- WARNING: THIS WILL DELETE ALL USER DATA. THIS CANNOT BE UNDONE.
-- ============================================================================

DO $$
DECLARE
    -- Find all tables in public schema except consent_content
    tables_query text := 'SELECT tablename FROM pg_tables WHERE schemaname = ''public'' AND tablename != ''consent_content''';
    table_record record;
    truncate_stmt text := 'TRUNCATE TABLE ';
    found_tables boolean := false;
BEGIN
    -- Loop through all tables found
    FOR table_record IN EXECUTE tables_query LOOP
        truncate_stmt := truncate_stmt || quote_ident(table_record.tablename) || ', ';
        found_tables := true;
    END LOOP;

    -- If we found tables, remove trailing comma and execute
    IF found_tables THEN
        truncate_stmt := substring(truncate_stmt from 1 for length(truncate_stmt)-2);
        truncate_stmt := truncate_stmt || ' CASCADE;';
        
        RAISE NOTICE 'Executing: %', truncate_stmt;
        EXECUTE truncate_stmt;
    ELSE
        RAISE NOTICE 'No tables found to truncate.';
    END IF;
END $$;
