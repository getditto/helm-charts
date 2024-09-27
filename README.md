# helm-charts

The home for public Helm charts for Ditto.

## Self hosting a Big Peer

Ditto offers a Helm chart for deploying a Big Peer on Kubernetes.
To install the chart, add the Ditto Helm repository:

```bash
  helm repo add ditto https://getditto.github.io/helm-charts/
```

We will then need to install some CRDs that are required for the Big Peer to run:

```bash
  kubectl apply --server-side --force-conflicts -f https://github.com/cert-manager/cert-manager/releases/download/v1.6.1/cert-manager.crds.yaml
  kubectl apply --server-side -f https://raw.githubusercontent.com/getditto/helm-charts/main/crds/ditto_v1alpha1_bigpeer_crd.yaml
  kubectl apply --server-side -f https://raw.githubusercontent.com/getditto/helm-charts/main/crds/ditto_v1alpha1_ditto_crd.yaml

```

Then using  the values file
[values.yaml](https://github.com/getditto/helm-charts/blob/main/charts/big-peer/values.yaml) 
which can be modified to suit your needs, install the chart:

```bash
  helm install ditto-bp ditto/big-peer -f values.yaml
```

This above command will install the Big Peer chart with the release name `ditto-bp`.

For ingress to work, you will need to have a working ingress controller in your cluster.
and then you can create an ingress resource that points to the k8s service in your install called
ditto-bp-hydra-subscription and map to port `8080`.

### Notes on dependencies

The `big-peer` chart has a few third-party dependencies that we include in the chart for ease of use and to ensure compatibility. but if you have these dependencies already installed in your cluster, you can disable the installation of these dependencies by setting the `enable` values to `false` in the values file for the respective dependency.

By default the following dependencies are enabled:

- [Strimzi Kafka Operator](https://strimzi.io/)
- [Cert Manager](https://github.com/cert-manager/cert-manager)
