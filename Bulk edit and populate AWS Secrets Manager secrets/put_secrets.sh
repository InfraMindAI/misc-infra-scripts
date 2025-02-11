#!/bin/zsh

# Validation

aws_profile_name="$1"

if [ -z "$aws_profile_name" ]; then
  echo "usage:   ./put_secrets.sh aws_profile_name"
  echo "example: ./put_secrets.sh dr"
  exit 1
fi

if [[ "$aws_profile_name" = *'prod'* ]]; then
  expected_answer='I am sure I want to overwrite secrets in prod environment'
  printf "You are about to overwrite secrets in prod environment. Type '$expected_answer' to proceed, or any other text to abort: "
  read answer
  
  if [ "$answer" != "$expected_answer" ]; then
  	exit 1
  fi
fi

# Writing secrets values

cd 'secrets'

for file_name in $(find . -type f -print)
do
  if [ $file_name = './secrets.txt' ]; then
    continue
  fi

  secret_value=`cat $file_name`
  if [ -z "$secret_value" ]; then
  	echo "Error: secret value cannot be empty - add value to $file_name"
  	continue
  fi
  
  secret_name=${file_name:2}
  echo "writing $secret_name"

  aws secretsmanager put-secret-value --secret-id $secret_name --secret-string $secret_value --no-cli-pager --profile $aws_profile_name > /dev/null
done