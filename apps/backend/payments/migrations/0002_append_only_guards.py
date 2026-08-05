"""Database-level append-only enforcement for the ledger tables.

Defense in depth: even a rogue query cannot UPDATE or DELETE a posted ledger
entry or posting. Installed only on PostgreSQL; on other backends (e.g. the
SQLite test fallback) this is a no-op and the ORM `AppendOnly` guard applies.
"""
from django.db import migrations

_TABLES = ["payments_ledgerentry", "payments_posting"]

_UP = """
CREATE OR REPLACE FUNCTION taifa_block_mutation() RETURNS trigger AS $$
BEGIN
    RAISE EXCEPTION 'append-only table: % operations are forbidden on %', TG_OP, TG_TABLE_NAME;
END;
$$ LANGUAGE plpgsql;
"""

_DOWN = "DROP FUNCTION IF EXISTS taifa_block_mutation() CASCADE;"


def install(apps, schema_editor):
    if schema_editor.connection.vendor != "postgresql":
        return
    with schema_editor.connection.cursor() as cursor:
        cursor.execute(_UP)
        for table in _TABLES:
            cursor.execute(
                f"DROP TRIGGER IF EXISTS {table}_append_only ON {table};"
            )
            cursor.execute(
                f"CREATE TRIGGER {table}_append_only "
                f"BEFORE UPDATE OR DELETE ON {table} "
                f"FOR EACH ROW EXECUTE FUNCTION taifa_block_mutation();"
            )


def uninstall(apps, schema_editor):
    if schema_editor.connection.vendor != "postgresql":
        return
    with schema_editor.connection.cursor() as cursor:
        for table in _TABLES:
            cursor.execute(f"DROP TRIGGER IF EXISTS {table}_append_only ON {table};")
        cursor.execute(_DOWN)


class Migration(migrations.Migration):
    dependencies = [("payments", "0001_initial")]
    operations = [migrations.RunPython(install, uninstall)]
