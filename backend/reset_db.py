import os
import shutil

if os.path.exists("db.sqlite3"):
    try:
        os.remove("db.sqlite3")
        print("Deleted db.sqlite3")
    except Exception as e:
        print(f"Failed to delete db.sqlite3: {e}")

apps = ["workouts", "exercises", "routines", "users"]
for app in apps:
    mig_dir = os.path.join("apps", app, "migrations")
    if os.path.exists(mig_dir):
        for f in os.listdir(mig_dir):
            if f.endswith(".py") and f != "__init__.py":
                try:
                    os.remove(os.path.join(mig_dir, f))
                    print(f"Deleted {os.path.join(mig_dir, f)}")
                except Exception as e:
                    print(f"Failed to delete {f}: {e}")
        
        pycache = os.path.join(mig_dir, "__pycache__")
        if os.path.exists(pycache):
            try:
                shutil.rmtree(pycache)
                print(f"Deleted {pycache}")
            except Exception as e:
                print(f"Failed to delete pycache: {e}")
