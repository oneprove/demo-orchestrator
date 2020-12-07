# VeracityProtocol - Identification

# Generate the JWT Signig keys

## Generate the Private/Public Key Pair
`mkdir -p /tmp/jwt && ssh-keygen -t rsa -b 4096 -m PEM -f /tmp/jwt/jwt.key -N "" <<< y >/dev/null && openssl rsa -in /tmp/jwt/jwt.key -pubout -outform PEM -out /tmp/jwt/jwt.key.pub`

## Copy private key to clipboard and paste it to the .env file
`cat /tmp/jwt/jwt.key | base64 | awk '{print "JWT_PRIVATE_KEY="$1}'`

## Copy public key to clipboard and paste it to the .env file
`cat /tmp/jwt/jwt.key.pub | base64 | awk '{print "JWT_PUBLIC_KEY="$1}'`

# ETC Hosts

add following to /etc/hosts

`127.0.0.1 demo.veracityprotocol.test`