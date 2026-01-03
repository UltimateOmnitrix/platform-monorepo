When this cmd gets executed in ( boosrap-foundation.yml ) teterraform init -backend-config="bucket=platformproject-481722-tf-state"  

a. It Reads all the .tf files in the prod directory and reads the cmds written in main.tf

b. and checks where to store the state file and by the way we passed it at the runtime with bucket name 

c. Next it looks for the provider, checks it and downlaods hte provider pulgins locally 

d. Next checks there is a module and download it in the .tf/module/iam_wif/ 




when this cmd gets executed  in (bootstrap-foundation.yml) terraform apply -auto-approve -var-file="prod.tfvars"

a. This applies with tf config using production variables, creates the IAM and WIF resosuce in GCP and enable secure, keyless Github Actions Authentication... 



