-- Optional least-privilege group roles for the local lab.
-- Run as the database administrator after the schema exists: make security-roles
-- No LOGIN roles or passwords are created here. Provision individual login roles
-- interactively using the instructions in docs/SECURITY_AND_PERFORMANCE.md.

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'lab_readonly') THEN
        CREATE ROLE lab_readonly NOLOGIN;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'lab_app') THEN
        CREATE ROLE lab_app NOLOGIN;
    END IF;
END
$$;

GRANT USAGE ON SCHEMA public TO lab_readonly, lab_app;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO lab_readonly;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO lab_app;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO lab_app;

-- Default privileges apply to future objects created by the role running this file.
ALTER DEFAULT PRIVILEGES IN SCHEMA public
    GRANT SELECT ON TABLES TO lab_readonly;
ALTER DEFAULT PRIVILEGES IN SCHEMA public
    GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO lab_app;
ALTER DEFAULT PRIVILEGES IN SCHEMA public
    GRANT USAGE, SELECT ON SEQUENCES TO lab_app;
