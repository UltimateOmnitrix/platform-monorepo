OF the PHASE1: 

1. Created the factory engine for infrastructure/factory/main.tf.. 
    It uses fileset() to scan infrastructure/factory/data/sandboxes/ to scan all the .yaml files dropped by Backstage... 
    uses for_each to dynamically create GCP storage bucket & assign IAM permission based on what's inside the YAML file... 

2. Created Sandbox Template, This is what developer sees... 
    I defined a UI form aksing for sandbox_name, owner_email & region...
    After clicking create, backstage takes those inputs & copies on Skeleton .yaml 
    Backstage replaces placeholder like ${{ values.sandbox_name }} with user's input  

3. CI/CD pipeline, PR is created with Github actions auth to GCP keylessly using WIF.. It runs tf plan to show facotry is about to build, Possts the pland direclty as a comment on Github Pull req and then next merge.


** PHASE2 **: 
1. Extending factory infrastructure/factory/apps.tf, 
    It scans YAML files in infrastructure/factory/data/apps/ for cloud run def, 
    It reads YAML files  & provisions google_cloud_run_v2_service each one 
    We set it up to deployg generic "Hello World" container (us-docker.pkg.dev/cloudrun/container/hello

2. The cloud Run template backstage/templates/cloudrun-app/template.yml, 
    Second backstage capability, UI asks for App_name, the sandbox_ref and env 
    Just like Phase1, copies a skeleton Yaml file & creates a PR in the platfom-monorepo.. 
    The YAML file lands in data/apps 


### GLIMPSE ### 
🔄 The Complete developer workflow (What you can test now)
Now that Phase 1 & 2 are complete, the workflow goes like this:

TIP

Try it yourself! Once you sync ArgoCD, go to your Backstage portal and follow these steps to see it in action.

Developer opens Backstage and clicks the "Create a GCP Sandbox" template.
Developer types test-box and clicks Create.
Backstage creates a PR adding infrastructure/factory/data/sandboxes/test-box.yaml.
You merge the PR. GitHub Actions runs and creates the sandbox-test-box-prodaccount GCS bucket in Google Cloud.
Developer returns to Backstage and clicks "Cloud Run App Capability".
Developer types my-api, ties it to test-box, and clicks Create.
Backstage creates a PR adding infrastructure/factory/data/apps/my-api.yaml.
You merge the PR. GitHub Actions runs and deploys the my-api Cloud Run service to GCP.
All of this happens without a single developer ever writing or touching Terraform code. 🤯