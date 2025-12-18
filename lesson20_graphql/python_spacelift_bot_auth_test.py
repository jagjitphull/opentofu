import requests
import json

# --- UPDATE THESE CAREFULLY ---
SPACELIFT_ORG = "ilglabs"
API_KEY_ID = "01KCNN6JP8SA69PRQFYYKNJRZY"      # Check for extra spaces!
API_KEY_SECRET = "d1a70bc723c2ea6aa84a626daf44429200be97fe530f2a2111d8431329da43a9"

API_URL = f"https://{SPACELIFT_ORG}.app.spacelift.io/graphql"

def debug_auth():
    print(f"Testing auth for: {API_URL}")
    
    mutation = """
    mutation GetToken($keyId: ID!, $keySecret: String!) {
      apiKeyUser(id: $keyId, secret: $keySecret) {
        jwt
      }
    }
    """
    
    response = requests.post(
        API_URL, 
        json={'query': mutation, 'variables': {"keyId": API_KEY_ID, "keySecret": API_KEY_SECRET}}
    )

    print(f"\nStatus Code: {response.status_code}")
    print("Raw Response:")
    print(json.dumps(response.json(), indent=2))

debug_auth()
