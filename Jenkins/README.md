# Quickstart
Run jenkins docker compose
```bash
docker compose up -d
```

# Groovy
Write a pipeline from scratch that will do the following:
Trigger from SCM change -> build an artifact -> pack the artifact and upload to repo.
Please use Groovy Shared-Libraries and create a function called prepareEnv. This function
should be able to pass SCM trigger parameters into the groovy pipeline (for example, who was
the code committer in the SCM)