#!/bin/bash
# ~/.spacelift-jwt-config
#cp the script into your home dir as . file
# source ~/.spacelift-jwt-config

# JWT Token (get new token from Postman when expired)
export SPACELIFT_TOKEN="eyJhbGciOiJLTVMiLCJ0eXAiOiJKV1QifQ.eyJhdWQiOlsiaHR0cHM6Ly9pbGdsYWJzLmFwcC5zcGFjZWxpZnQuaW8iXSwiZXhwIjoxNzY4MDU0NzI3LjQzNjk1OSwianRpIjoiMDFLRUsyMU1HQ1lQQ05KOUpHOVgxQ04zR1giLCJpYXQiOjE3NjgwMTg3MjcuNDM2OTU5LCJpc3MiOiJhcGkta2V5IiwibmJmIjoxNzY4MDE4NzI3LjQzNjk1OSwic3ViIjoiYXBpOjowMUtDTk42SlA4U0E2OVBSUUZZWUtOSlJaWSIsImFkbSI6dHJ1ZSwiYXZ0IjoiaHR0cHM6Ly93d3cuZ3JhdmF0YXIuY29tL2F2YXRhci83Mzk2ZGIyYzQ4YzM3MmM0YmFlMDQ1MmVkZjNjZTM4ODY1ODllYmQ5NjU1MTEyZjE4YjQzMGEzMmMxMmI1Yzk2LmpwZz9kPXJvYm9oYXNoXHUwMDI2c2l6ZT04MCIsImNpcCI6IjExNC43OS4xNzYuMTgzIiwicHNhIjoiMDFLRUsyMU1INzc4WURXS0hOWEY2RktTOE4iLCJJc01hY2hpbmVVc2VyIjpmYWxzZSwiSXNJbnRlZ3JhdGlvbiI6ZmFsc2UsInN1YmRvbWFpbiI6ImlsZ2xhYnMiLCJmdWxsX25hbWUiOiJncmFwaHFsLWFwaS1rZXlzIn0.VROvJr2Kqx4CZ+P3T4maapPPDD5wFF/Zhu5tTDzjEwu0qTKmxSMEl33I7l7LNO+JQuzx/3N1BOrxvpVuCS1adJJI0Kkt4eLdxOFCPJXL1hbHgSkQRLcq1BsAno8Yyftq8DN6DyQtpQ3iAw0f7ZVJNbAD4TgbD6vVpUVIA4hk2BgCcsbnCxjz/tkW1vGwzxdnhexr+NhA7/iatDFoLt4+PhY6Hlyx68t0Si3Py3cE8WXzF1mW1RbKXZs0fuxMi0rjOH9sZbjgLgAkbeAjlzczG8rGMj/uJ+fNqPxdqnX4QIt77fcYpjx8VRyo8bzDotXWuPd47G1mP1eWfQB2tJNbaedxOa/Yhvu+sacTvuu00J0A/6Pk2w9HZA7nIoJky6OpN5JcnOPnS93XkkYxwmZCsSQi/1AakMrwrS4DHgStsVh9xtdTr8jAOpUYt9Q7SgoatG5faVopt3SZYliFBBcydXLp9f6B9ELX1L9fLDt80k7TwvfGTNKo6QrTF5xRUudClCRnPfiEWCWGRZygndL7w5unKBQQ1Ve/qTk/tmAJ8zEHVuiajCnjR46a8HuBiGx3kIc9tOCQW3yb2GXeR8Jp8TlA3O7Yp7v2w9vZpBuuAruMcXlKczMyR9RX0RLRn1aMcNe96+ugynEOpf5n7ZzgkzxQmcLf/oGtIeHkQUY6MO0="

export SPACELIFT_ENDPOINT="https://ilglabs.app.spacelift.io/graphql"

# Helper aliases
alias spacelift-test='curl -s -X POST "$SPACELIFT_ENDPOINT" -H "Authorization: Bearer $SPACELIFT_TOKEN" -H "Content-Type: application/json" -d "{\"query\":\"query{stacks{id name state}}\"}" | jq .'
alias spacelift-runs='curl -s -X POST "$SPACELIFT_ENDPOINT" -H "Authorization: Bearer $SPACELIFT_TOKEN" -H "Content-Type: application/json" -d "{\"query\":\"query{stack(id:\\\"ec2-demo-stack\\\"){runs{id state type}}}\"}" | jq .'~                                                                
