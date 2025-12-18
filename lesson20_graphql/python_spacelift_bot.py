import requests
import json
import sys

# --- CONFIGURATION ---
# Use the exact same credentials that worked in your debug script
SPACELIFT_ORG = "ilglabs"
API_KEY_ID = "01KCNN6JP8SA69PRQFYYKNJRZY"      # <--- Paste your working ID here
API_KEY_SECRET = "d1a70bc723c2ea6aa84a626daf44429200be97fe530f2a2111d8431329da43a9"  # <--- Paste your working Secret here

# Endpoint
GRAPHQL_URL = f"https://{SPACELIFT_ORG}.app.spacelift.io/graphql"

def run_query(query, variables=None, token=None):
    headers = {"Content-Type": "application/json"}
    if token:
        headers["Authorization"] = f"Bearer {token}"

    response = requests.post(
        GRAPHQL_URL,
        json={'query': query, 'variables': variables},
        headers=headers
    )
    
    if response.status_code != 200:
        raise Exception(f"Query failed: {response.status_code} - {response.text}")
    
    result = response.json()
    if 'errors' in result:
        print(f"⚠️ GraphQL Errors: {json.dumps(result['errors'], indent=2)}")
        return None
        
    return result.get('data')

def get_token():
    print(f"🔑 Authenticating with {SPACELIFT_ORG}...")
    query = """
    mutation GetToken($keyId: ID!, $keySecret: String!) {
      apiKeyUser(id: $keyId, secret: $keySecret) { jwt }
    }
    """
    data = run_query(query, variables={"keyId": API_KEY_ID, "keySecret": API_KEY_SECRET})
    
    if data is None or data.get('apiKeyUser') is None:
        print("❌ CRITICAL ERROR: Authentication failed (Token is None).")
        print("   Please check your API_KEY_ID and API_KEY_SECRET.")
        sys.exit(1)
        
    return data['apiKeyUser']['jwt']

def list_stacks(token):
    print("\n📋 Fetching Stacks...")
    query = """
    {
      stacks {
        id
        name
        state
        administrative
      }
    }
    """
    data = run_query(query, token=token)
    if not data:
        return []
        
    stacks = data['stacks']
    
    print(f"{'ID':<30} {'NAME':<30} {'STATE':<15}")
    print("-" * 75)
    for stack in stacks:
        # Handle cases where name might be None
        s_id = stack['id']
        s_name = stack['name'] or "N/A"
        s_state = stack['state']
        print(f"{s_id:<30} {s_name:<30} {s_state:<15}")
    return stacks

def trigger_run(token, stack_id):
    print(f"\n🚀 Triggering run for stack: {stack_id}...")
    mutation = """
    mutation TriggerRun($stackId: ID!) {
      runTrigger(stack: $stackId) {
        id
        state
        createdAt
      }
    }
    """
    data = run_query(mutation, variables={"stackId": stack_id}, token=token)
    
    if data and data.get('runTrigger'):
        run_info = data['runTrigger']
        print(f"✅ Run Triggered Successfully!")
        print(f"   Run ID: {run_info['id']}")
        print(f"   State:  {run_info['state']}")
    else:
        print("❌ Failed to trigger run.")

# --- MAIN EXECUTION ---
if __name__ == "__main__":
    try:
        # 1. Get Token
        jwt = get_token()
        print("✅ Auth Successful.")
        
        # 2. List Stacks
        my_stacks = list_stacks(jwt)
        
        if not my_stacks:
            print("\nNo stacks found (or permission denied).")
        else:
            # 3. Interactive Trigger
            target_stack = input("\nEnter a Stack ID to trigger a run (or press Enter to skip): ").strip()
            if target_stack:
                trigger_run(jwt, target_stack)
            else:
                print("Skipping trigger.")

    except Exception as e:
        print(f"❌ Error: {e}")
