# Ops Lambdas

## Some Lambdas in Ruby to help glue pipelines

## Be up to date on your sam

pip install --user --upgrade aws-sam-cli

## Params in use

aws ssm put-parameter --name "SlackUrl" --value "a value" --type "String"

aws ssm put-parameter --name "EcsTargetsForGroup" --value "a value" --type "String"

aws ssm put-parameter --name "EcsGroupToAddToTargetGroup" --value "a value" --type "String"

## Build and Deploy

./build some-bucket some-stack