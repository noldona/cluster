variable "username" {
  type        = string
  description = "Username to use"
  nullable    = false
}

variable "private_key" {
  type        = string
  description = "Path to the private key"
  nullable    = false
}

variable "host" {
  type = object({
    head     = string
    worker1  = string
    worker2  = string
    worker3  = string
    worker4  = string
    worker5  = string
    worker6  = string
    worker7  = string
    worker8  = string
    worker9  = string
    worker10 = string
    worker11 = string
  })
  nullable = false
}

variable "enabled_sites" {
  type = list(string)
}

variable "enabled_streams" {
  type = list(string)
}

terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0.1"
    }

    null = {
      version = "~> 3.2.2"
    }
  }
}

provider "docker" {
  host = "ssh://${var.username}@${var.host.head}:22"
}

resource "null_resource" "nginx_files" {
  connection {
    type        = "ssh"
    host        = var.host.head
    user        = var.username
    private_key = file(var.private_key)
  }

  provisioner "file" {
    source      = abspath("${path.module}/conf")
    destination = "/var/nginx"
  }
  provisioner "file" {
    source      = abspath("${path.module}/html")
    destination = "/var/nginx"
  }
}

resource "docker_network" "cluster_public" {
  connection {
    type        = "ssh"
    host        = var.host.head
    user        = var.username
    private_key = file(var.private_key)
    timeout     = "1m"
  }

  name   = "cluster_public"
  driver = "bridge"
}

resource "docker_network" "cluster_private" {
  connection {
    type        = "ssh"
    host        = var.host.head
    user        = var.username
    private_key = file(var.private_key)
    timeout     = "1m"
  }

  name   = "cluster_private"
  driver = "bridge"
}

resource "docker_image" "nginx" {
  connection {
    type        = "ssh"
    host        = var.host.head
    user        = var.username
    private_key = file(var.private_key)
    timeout     = "1m"
  }

  name         = "nginx"
  keep_locally = false
}

resource "docker_container" "nginx" {
  connection {
    type        = "ssh"
    host        = var.host.head
    user        = "192.168.1.31"
    private_key = file(var.private_key)
    timeout     = "1m"
  }

  image    = docker_image.nginx.image_id
  name     = "nginx"
  restart  = "always"
  hostname = "nginx"
  networks_advanced {
    name = docker_network.cluster_public.id
  }
  networks_advanced {
    name = docker_network.cluster_private.id
  }
  volumes {
    container_path = "/etc/nginx/sites-available"
    host_path      = "/var/nginx/conf/sites-available"
    read_only      = true
  }
  volumes {
    container_path = "/etc/nginx/streams-available"
    host_path      = "/var/nginx/conf/streams-available"
    read_only      = true
  }
  volumes {
    container_path = "/etc/nginx/nginx.conf"
    host_path      = "/var/nginx/conf/nginx.conf"
    read_only      = true
  }
  # volumes {
  #   container_path = "/etc/nginx/conf.d/certs"
  #   host_path      = abspath("${path.module}/conf/certs")
  #   read_only      = true
  # }
  volumes {
    container_path = "/var/www/html"
    host_path      = "/var/nginx/html"
  }
  # volumes {
  #   container_path = "/etc/letsencrypt"
  #   host_path      = "/etc/letsencrypt"
  #   read_only      = true
  # }
  ports {
    internal = 80
    external = 80
  }
  ports {
    internal = 443
    external = 443
  }

  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      host        = var.host.head
      user        = var.username
      private_key = file(var.private_key)
      timeout     = "1m"
    }

    inline = [
      "docker exec nginx /bin/bash -c 'mkdir /etc/nginx/sites-enabled'",
      "docker exec nginx /bin/bash -c 'mkdir /etc/nginx/streams-enabled'"
    ]
  }

}

resource "null_resource" "enabled_sites" {
  for_each = toset(var.enabled_sites)

  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      host        = var.host.head
      user        = var.username
      private_key = file(var.private_key)
      timeout     = "1m"
    }

    inline = [
      "docker exec nginx /bin/bash -c 'ln -s /etc/nginx/sites-available/${each.value}.conf /etc/nginx/sites-enabled/${each.value}.conf'",
      "docker exec nginx /bin/bash -c 'nginx -s reload'"
    ]
  }

  depends_on = [docker_container.nginx]
}

resource "null_resource" "enabled_streams" {
  for_each = toset(var.enabled_streams)

  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      host        = var.host.head
      user        = var.username
      private_key = file(var.private_key)
      timeout     = "1m"
    }

    inline = [
      "docker exec nginx /bin/bash -c 'ln -s /etc/nginx/streams-available/${each.value}.conf /etc/nginx/streams-enabled/${each.value}.conf'",
      "docker exec nginx /bin/bash -c 'nginx -s reload'"
    ]
  }

  depends_on = [docker_container.nginx]
}
