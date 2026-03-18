import requests

BASE_URL = "http://127.0.0.1:8000/api"

def test_api():
    print("=== 1. Probando REGRISTRO ===")
    user_data = {
        "username": "atleta_prueba",
        "email": "atleta@heft.com",
        "password": "super_password_123"
    }
    
    response = requests.post(f"{BASE_URL}/auth/register/", json=user_data)
    if response.status_code in [201, 400]:
        print(f"Status: {response.status_code}")
        try:
            data = response.json()
            print("Respuesta Registro:", data)
            
            # Si el registro fue exitoso o el usuario ya existía (ignoramos el error y pedimos login)
            if 'tokens' in data:
                token = data['tokens']['access']
            else:
                # El usuario ya existe, hagamos login para el token
                print("\n=== El usuario ya existe. Haciendo LOGIN ===")
                login_resp = requests.post(f"{BASE_URL}/auth/login/", json={"username": "atleta_prueba", "password": "super_password_123"})
                token = login_resp.json()['access']
                
            print(f"\n✅ Token obtenido: {token[:30]}...")
            
            print("\n=== 2. Pidiendo EJERCICIOS con Token ===")
            headers = {"Authorization": f"Bearer {token}"}
            ejercicios_resp = requests.get(f"{BASE_URL}/exercises/", headers=headers)
            print(f"Status Ejercicios: {ejercicios_resp.status_code}")
            
            ejercicios = ejercicios_resp.json()
            print(f"Total de ejercicios obtenidos: {len(ejercicios)}")
            # Mostrar los 3 primeros
            for ej in ejercicios[:3]:
                print(f" - {ej['name']} ({ej['muscle_group']})")
                
        except Exception as e:
            print("Error parseando respuesta:", e)
    else:
        print("Error en registro:", response.status_code, response.text)

if __name__ == "__main__":
    test_api()
