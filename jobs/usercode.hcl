job "dagster-app" {
  datacenters = ["dc1"]
  type        = "service"

  meta {
    deploy = uuidv4()
  }

  group "dagster-app" {
    network{
      dns {
        servers = ["${attr.unique.network.ip-address}"]
      }

      port "http" {
        to = "4000"
      }
    }

    service {
      name = "dagster-app"
      port = "http"
      check {
        type     = "tcp"
        interval = "2s"
        timeout  = "2s"
      }
    }

    task "dagster-app" {
      restart {
        attempts = 1
        interval = "10m"
        delay    = "15s"
        mode     = "fail"
      }

      driver = "docker"

      env {
        DAGSTER_CURRENT_IMAGE = "gfaru/dagster-app:1.0.0"
      }

      config {
        image = "gfaru/dagster-app:1.0.0"
        # command = "/usr/bin/sh"
        # args = ["-c", "while true; do echo Waiting...; sleep 5; done"]
        ports=["http"]
      }
      resources {
        cpu    = 100
        memory = 1300
      }
    }
  }
}
