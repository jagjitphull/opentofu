#!/bin/bash
# ~/.spacelift-jwt-config
#cp the script into your home dir as . file
# source ~/.spacelift-jwt-config

# JWT Token (get new token from Postman when expired)
export SPACELIFT_TOKEN="eyJhbGciOiJLTVMiLCJ0eXAiOiJKV1QifQ.eyJhdWQiOlsiaHR0cHM6Ly9pbGdsYWJzLmFwcC5zcGFjZWxpZnQuaW8iXSwiZXhwIjoxNzY1OTk3NDcwLjc5NTgwNywianRpIjoiMDFLQ05SMzRUQlJUVjZYMUY3WlZWMk1IWUIiLCJpYXQiOjE3NjU5NjE0NzAuNzk1ODA3LCJpc3MiOiJhcGkta2V5IiwibmJmIjoxNzY1OTYxNDcwLjc5NTgwNywic3ViIjoiYXBpOjowMUtDTk42SlA4U0E2OVBSUUZZWUtOSlJaWSIsImFkbSI6dHJ1ZSwiYXZ0IjoiaHR0cHM6Ly93d3cuZ3JhdmF0YXIuY29tL2F2YXRhci83Mzk2ZGIyYzQ4YzM3MmM0YmFlMDQ1MmVkZjNjZTM4ODY1ODllYmQ5NjU1MTEyZjE4YjQzMGEzMmMxMmI1Yzk2LmpwZz9kPXJvYm9oYXNoXHUwMDI2c2l6ZT04MCIsImNpcCI6IjU0Ljg2LjUwLjEzOSIsInBzYSI6IjAxS0NOUjM0VjVYV1hYOE0yWDlTWFdSU0E4IiwiSXNNYWNoaW5lVXNlciI6ZmFsc2UsIklzSW50ZWdyYXRpb24iOmZhbHNlLCJzdWJkb21haW4iOiJpbGdsYWJzIiwibWVtYmVyIjp0cnVlLCJmdWxsX25hbWUiOiJncmFwaHFsLWFwaS1rZXlzIn0.YUPkaYDGdLg+Mj2gK5DfmvZHWrB3jPXf4EbKcDSxXCMuPSHMYUtKYX2cz5FlR1mUnjqgBhj5urj0dkYgr5Eqt3mw/I00dtx77qxBBw7ppzykZm2cQ7rn25+G97ykAlLuSlDMHkKBp2f9LHJRehGSg6OhDY39zg3IMFgPJVkRlhFX+W11/SuYVhFUk8INZc3IHiG7iorq0CDoqUa8Fjpvg5esBspYXjn91+8tYWE3OFVISCiQ/KbfpuJfRvGkh8Vngi8MQ1HkV5e70a0onRH5lj2bZaleYbgQa+0MGlJyHhuVE3e2eVPaqWUjapthAFIlSAB3Y48uWecHSMqusr3CDmgnroRBhxlViuvIe+n5FoemCsuv0lHjilOWuRXQYGGnmSUlPZ65lqIh9k/i6lyjKLUZxvEZ6Lpj0eBu6f6qPoTOGKgfIVssnRLql8fBiK8tw0j2/OU5wr25i52vwS8pJPbOw1mshPt099WsT5XI/9NO+n9iR2yPW0U9bK4TwMhKQeNI31yH+EkyuiseRbUNMQyhNXcSlXjxr9ScvmRFtPCwjllz1wv/ru4CcEQmJe9XbRZEwNm8bx/eT6SIxDSTeo7YwO6R/+JBamfzwNKtExdQzLDeJ3jjDRWIVNjZZ5OPTcdxL4XHU9FsRsmXoDbmRw3ddEzsUMvgYuB+eHAe+yI="

export SPACELIFT_ENDPOINT="https://ilglabs.app.spacelift.io/graphql"

# Helper aliases
alias spacelift-test='curl -s -X POST "$SPACELIFT_ENDPOINT" -H "Authorization: Bearer $SPACELIFT_TOKEN" -H "Content-Type: application/json" -d "{\"query\":\"query{stacks{id name state}}\"}" | jq .'
alias spacelift-runs='curl -s -X POST "$SPACELIFT_ENDPOINT" -H "Authorization: Bearer $SPACELIFT_TOKEN" -H "Content-Type: application/json" -d "{\"query\":\"query{stack(id:\\\"ec2-demo-stack\\\"){runs{id state type}}}\"}" | jq .'~                                                                
