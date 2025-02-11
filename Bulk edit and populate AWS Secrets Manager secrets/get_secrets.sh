#!/bin/zsh

set -e

# Validation

aws_profile_name="$1"
secrets_base_path="$2"

if [ -z "$aws_profile_name" ] || [ -z "$secrets_base_path" ]; then
  echo "usage:   ./get_secrets.sh aws_profile_name secrets_base_path"
  echo "example: ./get_secrets.sh customer-prod prod/customer-management"
  exit 1
fi

secrets_parent_dir='secrets'

if [ -d $secrets_parent_dir ] 
then
  #we don't want to overwrite edits to secrets values if any if user will accidently run script again
  echo "Error: './$secrets_parent_dir' directory exists. Please delete/rename it." 
  exit 1
fi

# Read all secrets

mkdir $secrets_parent_dir

aws secretsmanager list-secrets --filter Key="name",Values="$secrets_base_path" --query "SecretList[*].Name" --max-items=2000 --output json --profile $aws_profile_name > $secrets_parent_dir/secrets.txt

# Put every secret value to file in directory, which matches secret path

{
  read

  while IFS= read -r secret_path
  do 
    if [ "$secret_path" = "]" ]; then
      break;
    fi

    secret_path=`echo $secret_path | tr -d '", '`
    echo "reading: $secret_path"

    file_path="./$secrets_parent_dir/$secret_path"

    value=`aws secretsmanager get-secret-value --secret-id $secret_path --query "SecretString" --no-paginate --no-cli-pager --output json --profile $aws_profile_name`
    value=${value:1:-1}
    value=`echo $value | tr -s '\\\"' '\"'`

    secret_dir="./$secrets_parent_dir/$(dirname $secret_path)"
    mkdir -p $secret_dir

    printf '%b' "$value" > "$file_path"
  done
} < $secrets_parent_dir/secrets.txt

echo "\nPlease edit secrets in './secrets' directory."