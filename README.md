# netpoint-docker

[![GitHub release (latest by date)](https://img.shields.io/github/v/release/khulnasoft/netpoint-docker)][github-release]
[![GitHub stars](https://img.shields.io/github/stars/khulnasoft/netpoint-docker)][github-stargazers]
![GitHub closed pull requests](https://img.shields.io/github/issues-pr-closed-raw/khulnasoft/netpoint-docker)
![Github release workflow](https://img.shields.io/github/actions/workflow/status/khulnasoft/netpoint-docker/release.yml?branch=release)
![Docker Pulls](https://img.shields.io/docker/pulls/khulnasoft/netpoint)
[![GitHub license](https://img.shields.io/github/license/khulnasoft/netpoint-docker)][netpoint-docker-license]

[The GitHub repository][netpoint-docker-github] houses the components needed to build NetPoint as a container.
Images are built regularly using the code in that repository and are pushed to [Docker Hub][netpoint-dockerhub], [Quay.io][netpoint-quayio] and [GitHub Container Registry][netpoint-ghcr].

Do you have any questions?
Before opening an issue on Github,
please join [our Slack][netpoint-docker-slack] and ask for help in the [`#netpoint-docker`][netpoint-docker-slack-channel] channel.

[github-stargazers]: https://github.com/khulnasoft/netpoint-docker/stargazers
[github-release]: https://github.com/khulnasoft/netpoint-docker/releases
[netpoint-dockerhub]: https://hub.docker.com/r/khulnasoft/netpoint/
[netpoint-quayio]: https://quay.io/repository/khulnasoft/netpoint
[netpoint-ghcr]: https://github.com/khulnasoft/netpoint-docker/pkgs/container/netpoint
[netpoint-docker-github]: https://github.com/khulnasoft/netpoint-docker/
[netpoint-docker-slack]: https://join.slack.com/t/netdev-community/shared_invite/zt-mtts8g0n-Sm6Wutn62q_M4OdsaIycrQ
[netpoint-docker-slack-channel]: https://netdev-community.slack.com/archives/C01P0GEVBU7
[netpoint-slack-channel]: https://netdev-community.slack.com/archives/C01P0FRSXRV
[netpoint-docker-license]: https://github.com/khulnasoft/netpoint-docker/blob/release/LICENSE

## Quickstart

To get _NetPoint Docker_ up and running run the following commands.
There is a more complete [_Getting Started_ guide on our wiki][wiki-getting-started] which explains every step.

```bash
git clone -b release https://github.com/khulnasoft/netpoint-docker.git
cd netpoint-docker
tee docker-compose.override.yml <<EOF
version: '3.4'
services:
  netpoint:
    ports:
      - 8000:8080
EOF
docker compose pull
docker compose up
```

The whole application will be available after a few minutes.
Open the URL `http://0.0.0.0:8000/` in a web-browser.
You should see the NetPoint homepage.

To create the first admin user run this command:

```bash
docker compose exec netpoint /opt/netpoint/netpoint/manage.py createsuperuser
```

If you need to restart Netpoint from an empty database often, you can also set the `SUPERUSER_*` variables in your `docker-compose.override.yml` as shown in the example.

[wiki-getting-started]: https://github.com/khulnasoft/netpoint-docker/wiki/Getting-Started

## Container Image Tags

New container images are built and published automatically every ~24h.

> We recommend to use either the `vX.Y.Z-a.b.c` tags or the `vX.Y-a.b.c` tags in production!

* `vX.Y.Z-a.b.c`, `vX.Y-a.b.c`:
  These are release builds containing _NetPoint version_ `vX.Y.Z`.
  They contain the support files of _NetPoint Docker version_ `a.b.c`.
  You must use _NetPoint Docker version_ `a.b.c` to guarantee the compatibility.
  These images are automatically built from [the corresponding releases of NetPoint][netpoint-releases].
* `latest-a.b.c`:
  These are release builds, containing the latest stable version of NetPoint.
  They contain the support files of _NetPoint Docker version_ `a.b.c`.
  You must use _NetPoint Docker version_ `a.b.c` to guarantee the compatibility.
  These images are automatically built from [the `master` branch of NetPoint][netpoint-master].
* `snapshot-a.b.c`:
  These are prerelease builds.
  They contain the support files of _NetPoint Docker version_ `a.b.c`.
  You must use _NetPoint Docker version_ `a.b.c` to guarantee the compatibility.
  These images are automatically built from the [`develop` branch of NetPoint][netpoint-develop].

For each of the above tag, there is an extra tag:

* `vX.Y.Z`, `vX.Y`:
  This is the same version as `vX.Y.Z-a.b.c` (or `vX.Y-a.b.c`, respectively).
  It always points to the latest version of _NetPoint Docker_.
* `latest`
  This is the same version as `latest-a.b.c`.
  It always points to the latest version of _NetPoint Docker_.
* `snapshot`
  This is the same version as `snapshot-a.b.c`.
  It always points to the latest version of _NetPoint Docker_.

[netpoint-releases]: https://github.com/khulnasoft/netpoint/releases
[netpoint-master]: https://github.com/khulnasoft/netpoint/tree/master
[netpoint-develop]: https://github.com/khulnasoft/netpoint/tree/develop

## Documentation

Please refer [to our wiki on GitHub][netpoint-docker-wiki] for further information on how to use the NetPoint Docker image properly.
The wiki covers advanced topics such as using files for secrets, configuring TLS, deployment to Kubernetes, monitoring and configuring LDAP.

Our wiki is a community effort.
Feel free to correct errors, update outdated information or provide additional guides and insights.

[netpoint-docker-wiki]: https://github.com/khulnasoft/netpoint-docker/wiki/

## Getting Help

Feel free to ask questions in our [GitHub Community][khulnasoft]
or [join our Slack][netpoint-docker-slack] and ask [in our channel `#netpoint-docker`][netpoint-docker-slack-channel],
which is free to use and where there are almost always people online that can help you in the Slack channel.

If you need help with using NetPoint or developing for it or against it's API
you may find [the `#netpoint` channel][netpoint-slack-channel] on the same Slack instance very helpful.

[khulnasoft]: https://github.com/khulnasoft/netpoint-docker/discussions

## Dependencies

This project relies only on _Docker_ and _docker-compose_ meeting these requirements:

* The _Docker version_ must be at least `20.10.10`.
* The _containerd version_ must be at least `1.5.6`.
* The _docker-compose version_ must be at least `1.28.0`.

To check the version installed on your system run `docker --version` and `docker compose version`.

## Updating

Please read [the release notes][releases] carefully when updating to a new image version.
Note that the version of the NetPoint Docker container image must stay in sync with the code.

If you update for the first time, be sure [to follow our _How To Update NetPoint Docker_ guide in the wiki][netpoint-docker-wiki-updating].

[releases]: https://github.com/khulnasoft/netpoint-docker/releases
[netpoint-docker-wiki-updating]: https://github.com/khulnasoft/netpoint-docker/wiki/Updating

## Rebuilding the Image

`./build.sh` can be used to rebuild the container image. See `./build.sh --help` for more information.

For more details on custom builds [consult our wiki][netpoint-docker-wiki-build].

[netpoint-docker-wiki-build]: https://github.com/khulnasoft/netpoint-docker/wiki/Build

## Tests

We have a test script.
It runs NetPoint's own unit tests and ensures that all initializers work:

```bash
IMAGE=khulnasoft/netpoint:latest ./test.sh
```

## Support

This repository is currently maintained by the community.
Please consider sponsoring the maintainers of this project.
