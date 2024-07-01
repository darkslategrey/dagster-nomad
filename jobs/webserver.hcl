job "dagster-web" {
  datacenters = ["dc1"]
  type        = "service"

  meta {
    deploy = uuidv4()
  }

  group "dagster-web" {
    network{
      dns {
        servers = ["${attr.unique.network.ip-address}"]
      }
      port "http" {}
    }
    service {
      name = "dagster-web"
      port = "http"
      tags = [
        "traefik.enable=true",
        "traefik.http.routers.dagster.rule=Host(`dagster.preprod.retailshake.com`)"
      ]
      check {
        type     = "tcp"
        interval = "2s"
        timeout  = "2s"
      }
    }


    task "dagster-web" {
      restart {
        attempts = 1
        interval = "10m"
        delay    = "15s"
        mode     = "fail"
      }

      driver = "docker"

      # workspace.yml
      template {
        data = <<EOH
load_from:
  # Each entry here corresponds to a service in the docker-compose file that exposes user code.
  - grpc_server:
      host: dagster-app.service.consul
      port: 27968
      # {{ range nomadService "dagster-app" }}
      # port: {{ .Port }}
      # {{ end}}
      location_name: "example_user_code"
EOH
        destination = "local/workspace.yml"
      }

      artifact {
        source = "https://gist.githubusercontent.com/darkslategrey/8c9cda1e9612607a2b8cd42003c15296/raw/064c6bfa0255e7d8081375f96ac311e528e8b762/dagster.yml"
        destination = "local/dagster.yaml"
      }

      template {
        data = <<EOH
#!/usr/bin/env sh
dagster-webserver -h "0.0.0.0" -p {{ env "NOMAD_PORT_http" }} -w  workspace.yml
EOH
        destination = "local/startup.sh"
        perms = "755"
      }

      env {
        DAGSTER_POSTGRES_USER = "dagster"
        DAGSTER_POSTGRES_PASSWORD = "dagster"
        DAGSTER_POSTGRES_DB = "dagster"
        DAGSTER_POSTGRES_HOSTNAME = "dagster-db.service.consul"
        DAGSTER_POSTGRES_PORT = 25234
      }

      config {
        # image = "radiohead.retailshake.com/rs-dagster:1.7.12-0.23.12"
        image = "gfaru/rs-dagster:1.7.12-0.23.12-1"
        entrypoint = ["/local/startup.sh"]
        # command = "/usr/bin/sh"
        # args = ["-c", "while true; do echo Waiting...; sleep 5; done"]
        ports=["http"]
        volumes = [
          "local/workspace.yml:/opt/dagster/dagster_home/workspace.yml",
          "local/dagster.yaml/dagster.yml:/opt/dagster/dagster_home/dagster.yaml"
        ]
      }
      resources {
        cpu    = 100
        memory = 1300
      }
    }
  }
}
