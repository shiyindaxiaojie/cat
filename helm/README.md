# CAT Helm chart

The chart deploys CAT as a StatefulSet and creates two CAT services:

- `<release>-server`: the normal service for HTTP (`8080`) and CAT TCP (`2280`).
- `<release>-server-headless`: the StatefulSet governing service used by `SERVER_URL`.

The Headless Service name is written to `/data/appdatas/cat/client.xml` when each
container starts. DNS is kept as a hostname, so CAT does not depend on fixed Pod
IPs. The image-provided `/data/appdatas/cat/datasources.xml` and `client.xml`
remain writable; only `/data/appdatas/cat/bucket` is mounted from the PVC.

```shell
helm upgrade --install cat ./helm --namespace cat --create-namespace \
  --set cat.mysql.rootpasswd='change-me'
```

For an external MySQL instance, disable the bundled database and provide its
connection settings:

```shell
helm upgrade --install cat ./helm --namespace cat --create-namespace \
  --set cat.mysql.enabled=false \
  --set cat.server.mysql.host=mysql.example.internal \
  --set cat.server.mysql.schema=cat \
  --set cat.server.mysql.password='change-me'
```

For multiple CAT replicas, set `cat.server.replicas`. The generated Headless
Service DNS remains stable as StatefulSet Pod IPs change.

Before deploying, publish the Dockerfile built by this repository and set
`cat.server.image.repository` / `cat.server.image.tag` to that image.
