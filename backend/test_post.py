import urllib.request, json
req = urllib.request.Request('http://127.0.0.1:8000/api/auth/register/', data=json.dumps({'username': 'test', 'email': 'test@test.com', 'password': 'Password123!'}).encode('utf-8'), headers={'Content-Type': 'application/json'})
try:
    res = urllib.request.urlopen(req)
    print('Success:', res.read().decode())
except Exception as e:
    print('Error:', e.read().decode())