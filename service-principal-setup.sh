#!/bin/bash

# Not needed for public, required for usgovernment, german, china
ARM_ENVIRONMENT=public
SP_NAME="Terraform-Cli"
FILE=./.env.sp

if test -f "$FILE"; then
    echo "$FILE exists."
else
    echo "Setting environment variables for Terraform"
    az extension add --upgrade --name account
    
    # Requires Python2
    INDEX_SUB=0
    ARM_SUBSCRIPTION_ID=$(az account subscription list 2>/dev/null | python2 -c "import json,sys;obj=json.load(sys.stdin);print obj[$INDEX_SUB]['subscriptionId'];")
    JSON_ARM_SERVICE_PRINCIPAL=$(az ad sp create-for-rbac --name="$SP_NAME" --role="Contributor" --scopes="/subscriptions/${ARM_SUBSCRIPTION_ID}")
    ARM_CLIENT_ID=$(echo $JSON_ARM_SERVICE_PRINCIPAL | python2 -c "import json,sys;obj=json.load(sys.stdin);print obj['appId'];")
    ARM_CLIENT_SECRET=$(echo $JSON_ARM_SERVICE_PRINCIPAL | python2 -c "import json,sys;obj=json.load(sys.stdin);print obj['password'];")
    ARM_TENANT_ID=$(echo $JSON_ARM_SERVICE_PRINCIPAL | python2 -c "import json,sys;obj=json.load(sys.stdin);print obj['tenant'];")
    
    
    # <<- EOF: https://riptutorial.com/bash/example/2135/indenting-here-documents
    cat <<-EOF > $FILE
		echo "Setting environment variables for Terraform"
		export ARM_SUBSCRIPTION_ID=$ARM_SUBSCRIPTION_ID
		export ARM_CLIENT_ID=$ARM_CLIENT_ID
		export ARM_CLIENT_SECRET=$ARM_CLIENT_SECRET
		export ARM_TENANT_ID=$ARM_TENANT_ID

		# Not needed for public, required for usgovernment, german, china
		export ARM_ENVIRONMENT=$ARM_ENVIRONMENT
EOF
fi
