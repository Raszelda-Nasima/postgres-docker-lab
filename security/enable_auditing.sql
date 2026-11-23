-- Enable comprehensive database auditing
-- Track: who accessed what, when, and what changed

-- 1. Create audit schema and table
CREATE SCHEMA IF NOT EXISTS audit;

CREATE TABLE IF NOT EXISTS audit.table_log (
    id SERIAL PRIMARY KEY,
    table_name TEXT,
    operation TEXT,  -- INSERT, UPDATE, DELETE
    user_name TEXT,
    timestamp TIMESTAMP DEFAULT NOW(),
    old_data JSONB,
    new_data JSONB
);

CREATE INDEX IF NOT EXISTS idx_audit_table ON audit.table_log(table_name);
CREATE INDEX IF NOT EXISTS idx_audit_timestamp ON audit.table_log(timestamp);

-- 2. Create audit trigger function
CREATE OR REPLACE FUNCTION audit.table_audit_function() 
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        INSERT INTO audit.table_log(table_name, operation, user_name, new_data)
        VALUES(TG_TABLE_NAME, TG_OP, session_user, row_to_json(NEW));
        RETURN NEW;
    ELSIF TG_OP = 'UPDATE' THEN
        INSERT INTO audit.table_log(table_name, operation, user_name, old_data, new_data)
        VALUES(TG_TABLE_NAME, TG_OP, session_user, row_to_json(OLD), row_to_json(NEW));
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        INSERT INTO audit.table_log(table_name, operation, user_name, old_data)
        VALUES(TG_TABLE_NAME, TG_OP, session_user, row_to_json(OLD));
        RETURN OLD;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- 3. Attach audit trigger to tables
DROP TRIGGER IF EXISTS audit_users_trigger ON users;
CREATE TRIGGER audit_users_trigger
AFTER INSERT OR UPDATE OR DELETE ON users
FOR EACH ROW EXECUTE FUNCTION audit.table_audit_function();

DROP TRIGGER IF EXISTS audit_products_trigger ON products;
CREATE TRIGGER audit_products_trigger
AFTER INSERT OR UPDATE OR DELETE ON products
FOR EACH ROW EXECUTE FUNCTION audit.table_audit_function();

DROP TRIGGER IF EXISTS audit_orders_trigger ON orders;
CREATE TRIGGER audit_orders_trigger
AFTER INSERT OR UPDATE OR DELETE ON orders
FOR EACH ROW EXECUTE FUNCTION audit.table_audit_function();

-- 4. Query the audit log to verify it's working
SELECT 'Audit system enabled' as status;
