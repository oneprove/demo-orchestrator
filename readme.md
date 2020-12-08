# VeracityProtocol - Identification

# Run with GPU

`docker-compose up`

# Run without GPU

`docker-compose -f docker-compose-nogpu.yml up`

# Generate the JWT Signig keys

## Generate the Private/Public Key Pair
`mkdir -p /tmp/jwt && ssh-keygen -t rsa -b 4096 -m PEM -f /tmp/jwt/jwt.key -N "" <<< y >/dev/null && openssl rsa -in /tmp/jwt/jwt.key -pubout -outform PEM -out /tmp/jwt/jwt.key.pub`

## Copy private key to clipboard and paste it to the .env file
`cat /tmp/jwt/jwt.key | base64 | awk 'NF {sub(/\r/, ""); printf "%s\\n",$0;}' | sed 's/[\][n]//g'`

## Copy public key to clipboard and paste it to the .env file
`cat /tmp/jwt/jwt.key.pub | base64 | awk 'NF {sub(/\r/, ""); printf "%s\\n",$0;}' | sed 's/[\][n]//g'`

# ETC Hosts

add following to /etc/hosts

`127.0.0.1 demo.veracityprotocol.test`

# Login to ECR

`aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 993298895423.dkr.ecr.us-east-1.amazonaws.com`
