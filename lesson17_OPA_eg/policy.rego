package aws.compliance

import rego.v1

# Helper: Define allowed types set
allowed_types := {"t2.micro", "t3.micro"}

# Rule 1: Restrict EC2 Instance Types
deny contains msg if {
    # Find all resources in the plan
    resource := input.resource_changes[_]
    
    # Filter for EC2 instances only
    resource.type == "aws_instance"
    
    # Check if the instance type is in the allowed list
    not allowed_types[resource.change.after.instance_type]
    
    # Return a specific error message
    msg := sprintf(
        "Invalid instance type: '%v'. Allowed types are: %v",
        [resource.change.after.instance_type, allowed_types]
    )
}

# Rule 2: Enforce Mandatory 'Environment' Tag
deny contains msg if {
    resource := input.resource_changes[_]
    resource.type == "aws_instance"
    
    # Check if 'Environment' tag exists
    not resource.change.after.tags.Environment
    
    msg := "EC2 instance is missing the mandatory 'Environment' tag."
}
