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

## Helm

Helm charts can be found under the `charts` directory.  Execute `helm --help`
for more information on executing helm commands.

The `identity-platform` dirctory contains the identity-platform helm chart.

### Identity platform configuration

When installing from a locally cloned git repository, it is recommended that
one does not edit the default `values.yaml` as it is git managed.  However, the
`values.yaml` file can be copied and then edited with desired configuration
updates.  e.g. `cp values.yaml values-override.yaml`

### Identity platform install

In order to deploy the identity platform, simply execute `helm` with the
desired options.  Example:

```bash
$ kubectl create namespace identity-platform
$ helm upgrade identity-platform \
    oci://us-docker.pkg.dev/forgeops-public/charts/identity-platform \
    --version 7.4 --namespace identity-platform --install \
    -f values-override.yaml
```

The above example installs version `7.4` of the helm chart from the repository.

The following example, when executed from the `charts/identity-platform`
directory, can be used to install from a locally cloned git repository:

```bash
$ kubectl create namespace identity-platform
$ helm upgrade identity-platform . \
    --namespace identity-platform --install -f values-override.yaml
```

### Identity platform uninstall

```bash
$ helm delete identity-platform -n identity-platform
```

