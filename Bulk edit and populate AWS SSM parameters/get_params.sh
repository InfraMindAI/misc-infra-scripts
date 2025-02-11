#!/bin/zsh

set -e

# Validation

aws_profile_name="$1"
params_base_path="$2"

if [ -z "$aws_profile_name" ] || [ -z "$params_base_path" ]; then
  echo "usage:   ./get_params.sh aws_profile_name parameters_base_path"
  echo "example: ./get_params.sh customer-prod /prod/customer-management"
  exit 1
fi

if [[ "$params_base_path" != '/'* ]]; then
  echo "parameters_base_path should start with '/', for example '/dev/customer-management'"
  exit 1
fi

params_parent_dir='parameters'

if [ -d $params_parent_dir ] 
then
  #we don't want to overwrite edits to parameters values if any if user will accidently run script again
  echo "Error: './$params_parent_dir' directory exists. Please delete/rename it." 
  exit 1
fi

# Read all parameters

mkdir $params_parent_dir

aws ssm get-parameters-by-path --path $params_base_path --recursive --query="Parameters[*].[Name, Value]" --with-decryption --max-items=2000 --output json --profile $aws_profile_name > $params_parent_dir/params.txt

# Put every parameter value to file in directory, which matches parameter path

{
  read

  while IFS= read line
  do 
    if [ "$line" = "]" ]; then
      break;
    fi

    read -r param_path
    param_path=`echo $param_path | tr -d '",'`

    read -r value
    value=${value:1:-1}
    value=`echo $value | tr -s '\\\"' '\"'`

    read

    param_dir="./$params_parent_dir$(dirname $param_path)"
    mkdir -p $param_dir

    file_path="./$params_parent_dir$param_path"
    echo "reading: $file_path"

    printf '%b' "$value" > "$file_path"
  done
} < $params_parent_dir/params.txt

echo "\nPlease edit parameters in './parameters' directory."