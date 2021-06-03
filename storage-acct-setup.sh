FILE=./.env.sa
LOCATION=centralus
RESOURCE_GROUP_NAME=terraformstate
STORAGE_ACCOUNT_NAME=tfstate$RANDOM$RANDOM
CONTAINER_NAME=tfstate

if test -f "$FILE"; then
    echo "$FILE exists."
else
    
    # Create resource group
    az group create --name $RESOURCE_GROUP_NAME --location $LOCATION
    
    # Create storage account
    az storage account create --resource-group $RESOURCE_GROUP_NAME --name $STORAGE_ACCOUNT_NAME --sku Standard_LRS --encryption-services blob
    
    # Get storage account key
    ARM_ACCESS_KEY=$(az storage account keys list --resource-group $RESOURCE_GROUP_NAME --account-name $STORAGE_ACCOUNT_NAME --query [0].value -o tsv)
    
    # Create blob container
    az storage container create --name $CONTAINER_NAME --account-name $STORAGE_ACCOUNT_NAME --account-key $ACCOUNT_KEY
    
    cat <<-EOF
		Enter this into your terraform file:
		terraform {
			backend "azurerm" {
				resource_group_name  = "$RESOURCE_GROUP_NAME"
				storage_account_name = "$STORAGE_ACCOUNT_NAME"
				container_name = "$CONTAINER_NAME"
				key = "terraform.tfstate"
			}
		}
EOF
    
    # <<- EOF: https://riptutorial.com/bash/example/2135/indenting-here-documents
    cat <<-EOF > $FILE
		echo "Setting storage account for Terraform"
		# Note: you should use a Key Vault to store your secrets. E.g.
		# export ARM_ACCESS_KEY=$(az keyvault secret show --name mySecretName --vault-name myKeyVaultName --query value -o tsv)
		export ARM_ACCESS_KEY=$ARM_ACCESS_KEY
		# Enter this into your terraform file (uncommented):
		# terraform {
		#    backend "azurerm" {
		#		 resource_group_name  = "$RESOURCE_GROUP_NAME"
		#        storage_account_name = "$STORAGE_ACCOUNT_NAME"
		#        container_name = "$CONTAINER_NAME"
		#        key = "terraform.tfstate"
		#    }
		# }
EOF
fi
