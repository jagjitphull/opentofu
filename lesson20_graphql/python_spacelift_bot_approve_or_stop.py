import requests
import json
import sys

# --- CONFIGURATION ---
SPACELIFT_ORG = "ilglabs"
# Replace these with your actual credentials
API_KEY_ID = "01KCNN6JP8SA69PRQFYYKNJRZY"
API_KEY_SECRET = "d1a70bc723c2ea6aa84a626daf44429200be97fe530f2a2111d8431329da43a9"

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
    if not data or not data.get('apiKeyUser'):
        print("❌ Auth Failed. Check credentials.")
        sys.exit(1)
    return data['apiKeyUser']['jwt']

def approve_run(token, stack_id, run_id):
    print(f"\n👍 Approving Run {run_id} on Stack {stack_id}...")
    mutation = """
    mutation ConfirmRun($stackId: ID!, $runId: ID!) {
      runConfirm(stack: $stackId, run: $runId) {
        id
        state
      }
    }
    """
    variables = {"stackId": stack_id, "runId": run_id}
    data = run_query(mutation, variables=variables, token=token)
    
    if data and data.get('runConfirm'):
        print(f"✅ Success! Run State: {data['runConfirm']['state']}")
    else:
        print("❌ Failed to approve run.")

def stop_run(token, stack_id, run_id):
    print(f"\nCc Stopping Run {run_id} on Stack {stack_id}...")
    mutation = """
    mutation StopRun($stackId: ID!, $runId: ID!) {
      runStop(stack: $stackId, run: $runId) {
        id
        state
      }
    }
    """
    variables = {"stackId": stack_id, "runId": run_id}
    data = run_query(mutation, variables=variables, token=token)
    
    if data and data.get('runStop'):
        print(f"✅ Success! Run State: {data['runStop']['state']}")
    else:
        print("❌ Failed to stop run.")

# --- MAIN INTERACTIVE LOOP ---
if __name__ == "__main__":
    jwt = get_token()
    
    print("\n--- Spacelift Action Bot ---")
    s_id = input("Enter Stack ID: ").strip()
    r_id = input("Enter Run ID:   ").strip()
    
    if not s_id or not r_id:
        print("❌ Both Stack ID and Run ID are required.")
        sys.exit(1)

    print("\nChoose Action:")
    print("1. Approve (Confirm)")
    print("2. Stop")
    choice = input("Select (1/2): ").strip()

    if choice == "1":
        approve_run(jwt, s_id, r_id)
    elif choice == "2":
        stop_run(jwt, s_id, r_id)
    else:
        print("Invalid choice.")
