import json
import urllib.request

# Test des Root-Endpunkts (GET)
print("Teste GET / ...")
try:
    with urllib.request.urlopen("http://127.0.0.1:8000/") as response:
        result = json.loads(response.read().decode("utf-8"))
        print("Erfolg:", result)
except Exception as e:
    print("Fehler:", e)

# Test des Task-Endpunkts (POST)
print("Teste POST /task ...")
try:
    req = urllib.request.Request(
        "http://127.0.0.1:8000/task",
        method="POST",
        headers={"Content-Type": "application/json"}
    )
    with urllib.request.urlopen(req) as response:
        result = json.loads(response.read().decode("utf-8"))
        print("Erfolg:", result)
except Exception as e:
    print("Fehler:", e)
