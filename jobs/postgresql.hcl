job "dagster-db" {
  datacenters = ["dc1"]
  type        = "service"

  group "dagster-db" {
    count = 1

    network{
      port "postgres" {
        # to = 5432
      }
    }
    service {
      name = "dagster-db"
      port = "postgres"
      tags = [
        "mysql",
        "traefik.enable=true",
        # "traefik.tcp.routers.mysql.entrypoints=mysql",
        # "traefik.tcp.routers.mysql.rule=HostSNI(`*`)"
        # "traefik.tcp.routers.mysql.tls=true"
      ]

      check {
        type     = "tcp"
        port = "postgres"
        # port     = "$(NOMAD_PORT_postgres)"
        interval = "10s"
        timeout  = "2s"
      }
    }

    task "dagster-db" {
      driver = "docker"
      env {
        PGPORT = "${NOMAD_PORT_postgres}"
        POSTGRES_USER= "dagster"
        POSTGRES_PASSWORD= "dagster"
        # POSTGRES_DB= "dagster"
      }

      config {
        ports=["postgres"]
        image = "postgres:15-alpine"
        # network_mode="host"
        volumes=[
          "local/postgres-db-volume:/var/lib/postgresql/data"
        ]

      }

      # resources {
      #   cpu    = 100
      #   memory = 1024
      # }
    }
  }
}
