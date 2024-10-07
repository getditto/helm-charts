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
  kubectl apply --server-side -f https://raw.githubusercontent.com/getditto/helm-charts/refs/heads/main/charts/big-peer/crds/ditto_v1alpha3_hydracluster_crd.yaml
  kubectl apply --server-side -f https://raw.githubusercontent.com/getditto/helm-charts/refs/heads/main/charts/big-peer/crds/ditto_v1alpha3_hydrapartition_crd.yaml

```

Then using  the values file
[values.yaml](https://github.com/getditto/helm-charts/blob/main/charts/big-peer/values.yaml) 
which can be modified to suit your needs, install the chart:

```bash
  helm install ditto-bp ditto/big-peer -f values.yaml
```

This above command will install the Big Peer chart with the release name `ditto-bp`.

### Ports

We expose the following ports in the Big Peer chart via the service named `ditto-bp-hydra-subscription`:

- 8080: The port for the Big Peer to listen on for incoming connections from Small Peers.
- 4040: The port for the Big Peer to listen on for incoming connections from other Big Peers.
- 10080: The port for the Big Peer to listen on for incoming HTTP API calls.

### Getting started in the cloud

If you are wanting to deploy a simple cloud environment that you can connect your small peers to.
We recommend creating a vm with a public ip in AWS, or your favorite cloud provider, and then following the guide
to install K3s on that vm. https://docs.k3s.io/quick-start

This will provide a simple kubernetes cluster that you can deploy
the Big Peer to following the same instructions above.

You can then set `ingress.enabled` to `true` and change the `ingress.hosts` to the ip of your vm or dns name if you have it.
This should leave you with a Big Peer that is accessible from the internet via `http://<ip>:80`

To Connect a small peer to your newly created big peer follow the instructions in the section below.

### Notes on dependencies

The `big-peer` chart has a few third-party dependencies that we include in the chart for ease of use and to ensure compatibility. but if you have these dependencies already installed in your cluster, you can disable the installation of these dependencies by setting the `enable` values to `false` in the values file for the respective dependency.

By default the following dependencies are enabled:

- [Strimzi Kafka Operator](https://strimzi.io/)
- [Cert Manager](https://github.com/cert-manager/cert-manager)



### Deploy in EKS Cluster

To deploy the Big Peer into a AWS EKS Cluster like EKS you will need to perform the following actions;

- Create the [EKSClusterRole](https://docs.aws.amazon.com/eks/latest/userguide/cluster-iam-role.html#create-service-role)


- Install [eksctl](https://eksctl.io/installation/)

- Deploy EKS cluster with eksctl command

<br/>

```shell
eksctl create cluster --name <cluster-name> --region <aws-region> --profile <aws-profile>
```
<br/>

- Once the cluster is up and running verify that you have [ebs-csi-driver](https://docs.aws.amazon.com/eks/latest/userguide/ebs-csi.html#managing-ebs-csi) running in the `kube-system` namespace. This ensures that you have the provisioner that will dynamicallly create the Persistent Volumes that the hydra-store and kafka zookeeper nodes will need.

<br/>

- If your default storageClass is not set as the the default storageClass you can do that by adding the line below to the annotations.

```yaml
  storageclass.kubernetes.io/is-default-class: "true"
```

<br/>

- Install and Configure and [ingress controller](https://github.com/kubernetes-sigs/aws-load-balancer-controller) like [AWS LoadBalancer Controller](https://kubernetes-sigs.github.io/aws-load-balancer-controller/latest/deploy/installation/) or [Ingress Nginx](https://github.com/kubernetes/ingress-nginx/blob/main/charts/ingress-nginx/README.md). Any Ingress Controller will work fine 

- Make sure you have access to the required registry to pull images from the helm chart. This can be done by create a secret that has the registry username,email and password/token.

<br/>

#### Helm Chart Ingress Config 

- In order to be able to access the big peer externally you need to configure the ingress in the values.yaml with a valid host name. To do this you will need to create a **CNAME** record that points to the loadbalancer created in the ingress service that has the type `LoadBalancer`.

- Then in your values.yaml file you will need to enable the ingress and update the `host` value with the hostname you created as shown below;

```yaml
ingress:
  main:
    # -- Enables or disables the ingress
    enabled: true

    # -- Make this the primary ingress (used in probes, notes, etc...).
    # If there is more than 1 ingress, make sure that only 1 ingress is marked as primary.
    primary: true

    # -- Override the name suffix that is used for this ingress.
    nameOverride:

    # -- Provide additional annotations which may be required.
    annotations:
      {}
      # kubernetes.io/ingress.class: traefik
      # kubernetes.io/tls-acme: "true"

    # -- Provide additional labels which may be required.
    labels: {}

    # -- Set the ingressClass that is used for this ingress.
    # Requires Kubernetes >=1.19
    ingressClassName: alb # "traefik"

    ## Configure the hosts for the ingress
    hosts:
      - # -- Host address. Helm template can be passed.
        host: eks.ditto-umbrella.live
        ## Configure the paths for the host
```

This will create an ingress pointing to the ingress-controller's loadbalancer. See the full values file in [here](./values/eks-values.yaml)

<br/>


### Big Peer in Production

Coming Soon...




### Connecting to a Big Peer with a small peer

If you are deploying to something like Kubernetes for Docker Desktop, you will have to port-forward port 8080 from the 
ditto-bp-hydra-subscription service to your local machine.
```bash
  kubectl port-forward svc/ditto-bp-hydra-subscription 8080
```

Next in your small peer client you will need to change a few configuration items to connect to the Big Peer running on your laptop.
these examples are in kotlin for Android but should work similarly for other platforms.

In your Ditto object you will need to setup an identity that looks like this.
```kotlin
 OnlineWithAuthentication(
    dependencies = androidDependencies,
    appId = "your-app-id",
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

You will also need to setup the DittoTransportConfig
to have a custom URL for the Big Peer.

```kotlin
val conf = DittoTransportConfig()
conf.connect.websocketUrls.add("ws://localhost:8080/")

ditto?.let { ditto ->
    ditto.transportConfig = conf
    ditto.startSync()
}

```

### Big Peer to Big Peer communication

With Two separate installations of the big peer helm chart in separate namespaces you can set them up to communicate with each other,
you will need to setup a few things.

You will have to know the "App ID" you intend to operator under. 
This can be generated by creating a v4 UUID as long as it is the same for all of the peers in you network (Big and Small).

add the following to the `additionalEnv` section of the values.yaml file for the `hydra-subscription` deployment.

```yaml
PEER_APP_ID: "your-app-id"
```

via the HTTP API (see the ports section we will make a few different calls.

```bash
curl -v --request POST \
      --url http://<big-peer>:10080/${app_id}/sub/v1/peer/connections \
      --header 'content-type: application/json' \
      --data '{ "addr": "localhost:4040" }'
```

Next we will need to make a call to setup the subscription query so that we sync the data between the two peers.

```bash
curl -v --request POST \
--url http://<big-peer>:10080/${app_id}/sub/v1/peer/subscriptions \
--header 'content-type: application/json' \
--data '{
           "queries": {
             "my_collection": ["true"]
           }
        }'

```

We should now see the two peers syncing data between each other.
