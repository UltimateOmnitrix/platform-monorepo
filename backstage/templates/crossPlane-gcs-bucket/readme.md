#### BACKSTAGE FLOW:::: 

1. First i have crated the GSA and bounded it to the KSA using workload identity in the prod/gke/main.f 
2. As of now we have given persimpols to crossplane to use that identity to speak with google, in the manifets/providers/service-account.yml created the KSA 
3. configured the projectID & InjectedIdentity in the manifets/providers/gcp-config.yml 


4. Next created a cloud SQL instance so Backstage can sotre the users, templates, catalog items...  from developer-portal/postgres-database.yml 

5. next updated the backage application manifest to inject github token & allow templates so it can run actions.. (registryGitOps/applications/backstage.yml) 

6. Created skeleton (blue print) where it has a standard crossplane YAML file with parameters backstage/templates/gcs-bucket/skeleton/bucket.yml 

7. Create template (the form): defined the UI form (asking for name & location) & actions (fetching the skeleton, publishing to github) 

8. 