import os
import django
from django.conf import settings
from django.db import connection

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'heft_core.settings')
django.setup()

with connection.cursor() as cursor:
    print("Dropping public schema cascade...")
    cursor.execute("DROP SCHEMA public CASCADE;")
    print("Recreating public schema...")
    cursor.execute("CREATE SCHEMA public;")
    print("Granting permissions...")
    cursor.execute("GRANT ALL ON SCHEMA public TO public;")
print("Neon database reset successfully.")
