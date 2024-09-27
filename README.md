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

### Ingress

For ingress to work, you will need to have a working ingress controller in your cluster.
and then you can create an ingress resource that points to the k8s service in your install called
ditto-bp-hydra-subscription and map to port `8080`.

If you are deploying to something like Kubernetes for Docker Desktop, you will have to port-forward port 8080 from the 
ditto-bp-hydra-subscription service to your local machine.
```bash
  kubectl port-forward svc/ditto-bp-hydra-subscription 8080
```


### Notes on dependencies

The `big-peer` chart has a few third-party dependencies that we include in the chart for ease of use and to ensure compatibility. but if you have these dependencies already installed in your cluster, you can disable the installation of these dependencies by setting the `enable` values to `false` in the values file for the respective dependency.

By default the following dependencies are enabled:

- [Strimzi Kafka Operator](https://strimzi.io/)
- [Cert Manager](https://github.com/cert-manager/cert-manager)

### Connecting to a Big Peer on my laptop

In order to connect to a Big Peer running on your laptop, you will need to expose the service to the host machine. via the above method of port forwarding.

Next in your small peer client you will need to change a few configuration items to connect to the Big Peer running on your laptop.
these examples are in kotlin for Android but should work similarly for other platforms.

In your Ditto object you will need to setup an identity that looks like this.
```kotlin
 OnlineWithAuthentication(
    dependencies = androidDependencies,
    appId = Constants.onlineAppId,
    customAuthUrl = "http://10.0.2.2:8080",
    enableDittoCloudSync = true,
    callback = AuthCallback(),
    //10.0.2.2 is the localhost for the Android emulator
),
```

Next you will need to create an AuthCallback class that looks like this:

```kotlin
class AuthCallback: DittoAuthenticationCallback {
    override fun authenticationRequired(authenticator: DittoAuthenticator) {
        println("Login request.")
        authenticator.login("full_access", "dummy-provider", { token, error ->
            if (error != null) {
              println("Login failed.")
            } else {
              println("Login successful.")
            }
        })
    }

    override fun authenticationExpiringSoon(
        authenticator: DittoAuthenticator,
        secondsRemaining: Long
    ) {
        println("Auth token expiring in $secondsRemaining seconds")
    }
}
```

you will also need to setup the DittoTransportConfig to have a custom URL for the Big Peer.

```kotlin
val conf = DittoTransportConfig()
conf.connect.websocketUrls.add("ws://localhost:8080/")

ditto?.let { ditto ->
    ditto.transportConfig = conf
    ditto.startSync()
}

```

### Big Peer to Big Peer communication

If you have multiple Big Peers running in your cluster, you can enable Big Peer to Big Peer communication by adding the following items to your values files on one of the Big Peers:
