#!/bin/zsh

# Validation

aws_profile_name="$1"

if [ -z "$aws_profile_name" ]; then
  echo "usage:   ./put_params.sh aws_profile_name"
  echo "example: ./put_params.sh dr"
  exit 1
fi

if [[ "$aws_profile_name" = *'prod'* ]]; then
  expected_answer='I am sure I want to overwrite parameters in prod environment'
  printf "You are about to overwrite parameters in prod environment. Type '$expected_answer' to proceed, or any other text to abort: "
  read answer
  
  if [ "$answer" != "$expected_answer" ]; then
  	exit 1
  fi
fi

# Writing parameters values

cd 'parameters'

for file_name in $(find . -type f -print)
do
  if [ $file_name = './params.txt' ]; then
    continue
  fi

  parameter_value=`cat $file_name`
  if [ -z "$parameter_value" ]; then
  	echo "Error: parameter value cannot be empty - add value to $file_name"
  	continue
  fi
  
  parameter_name=${file_name:1}
  echo "writing $parameter_name"

  aws ssm put-parameter --name $parameter_name --value $parameter_value --overwrite --no-cli-pager --profile $aws_profile_name > /dev/null
done