provider "aws" {
  region = "us-east-2"
}

data "aws_eks_cluster" "cluster" {
  name = "eks-cluster-name"  # Replace with your EKS cluster name
}

data "aws_eks_cluster_auth" "cluster" {
  name = data.aws_eks_cluster.cluster.name
}


output "cluster_url" {
  value = data.aws_eks_cluster.cluster.endpoint
}

output "cluster_ca" {
  value = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
}

output "cluster_token" {
  sensitive = true
  value = data.aws_eks_cluster_auth.cluster.token
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}

resource "kubernetes_namespace" "example" {
  metadata {
    name = "example-namespace213123124"
  }
}

resource "kubernetes_deployment" "nginx" {
  metadata {
    name      = "nginx-deployment"
    namespace = kubernetes_namespace.example.metadata[0].name
  }

  spec {
    replicas = 2

    selector {
      match_labels = {
        app = "nginx"
      }
    }

    template {
      metadata {
        labels = {
          app = "nginx"
        }
      }

      spec {
        container {
          name  = "nginx"
          image = "nginx:1.14.2"

          port {
            container_port = 80
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "nginx" {
  metadata {
    name      = "nginx-service"
    namespace = kubernetes_namespace.example.metadata[0].name
  }

  spec {
    selector = {
      app = "nginx"
    }

    port {
      port        = 80
      target_port = 80
    }

    type = "LoadBalancer"
  }
}

resource "kubernetes_service" "db_service" {
  metadata {
    name = "db-service"
    namespace = kubernetes_namespace.example.metadata[0].name
  }

  spec {
    selector = {
      app = "db-app"
    }

    port {
      port        = 5432  # Replace with your database port
      target_port = 5432  # Replace with your database port
    }

    # Change the type to one of the following: ClusterIP, NodePort, LoadBalancer
    type = "LoadBalancer"
  }
}

resource "kubernetes_deployment" "db_deployment" {
  metadata {
    name = "db-deployment"
    namespace = kubernetes_namespace.example.metadata[0].name
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "db-app"
      }
    }

    template {
      metadata {
        labels = {
          app = "db-app"
        }
      }

      spec {
        container {
          name  = "db-container"
          image = "postgres:latest"  # Replace with your database image

          port {
            container_port = 5432  # Replace with your database port
          }

          env {
            name  = "POSTGRES_DB"
            value = "mydatabase"  # Replace with your database name
          }

          env {
            name  = "POSTGRES_USER"
            value = "myuser"  # Replace with your database user
          }

          env {
            name  = "POSTGRES_PASSWORD"
            value = "mypassword"  # Replace with your database password
          }
        }
      }
    }
  }
}