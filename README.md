# forgeops-extras
Terraform and other artifacts that can be used with the forgeops project.

## Terraform

### Configuration

In the toplevel `terraform` directory, the `terraform.tfvars` file can be
found.  That file provides the variable settings used to create/configure
clusters for GKE, EKS, and AKS.

In order to configure the desired clusters, it is recommended that
`terraform.tfvars` be copied to `override.auto.tfvars`.  The
`override.auto.tfvars` file can then be modified with the desired cluster
settings.

See the terraform documentation for more information on terraform variable
definitions:
https://www.terraform.io/docs/configuration/variables.html#variable-definitions-tfvars-files

### Cluster creation

In the `terraform` directory, after configuring your clusters, simply execute
the `tf-apply` helper script:

```bash
$ ./tf-apply
```

### Cluster teardown

There is a complimentary `tf-destroy` helper script that can be used to
bring down previously created clusters.  If there is more than one cluster
being managed in the configuration, a specific cluster can be destroyed
simply by specifing the cluster configuration name with the `-target` flag:

```bash
$ ./tf-destroy -target=module.<cluster_config>
```

