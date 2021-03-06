
provider "kubernetes" {
  config_context_cluster = "minikube"
}

resource "kubernetes_service" "kub_ser_rn" {
  metadata {
    name = "wordpress-service"
  }
  spec {
    selector = {
      app = "wordpress"
    }
    
    port {
      node_port = 30000
      port        = 80
      target_port = 80
    }

    type = "NodePort"
  }
}





resource "kubernetes_deployment" "dep_rn" {
  metadata {
    name = "wordpress"
   labels = {
          env = "prod"
        }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        env = "prod"
      }
    }

    template {
      metadata {
        labels = {
          env = "prod"
        }
      }

      spec {
          
        container {
          image = "wordpress:4.8-apache"
          name  = "wordpress"
            port{
                container_port = 80
            }
         
        
            
          
        }
      }
    }
  }
}
