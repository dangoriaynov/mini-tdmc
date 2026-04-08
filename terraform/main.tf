                                                                               
  # --- Namespaces ---                                                                                
  resource "kubernetes_namespace" "control_plane" {
    metadata {                                                                                        
      name = "mini-tdmc-control-plane"                                                                
      labels = {                                                                                      
        "app.kubernetes.io/managed-by" = "terraform"                                                  
        "purpose"                      = "control-plane"                                              
      }                                                                                               
    }                                                                              
  }                          
                                
  resource "kubernetes_namespace" "data_plane" {
    metadata {                                                                                        
      name = "mini-tdmc-data-plane"
      labels = {                                                                                      
        "app.kubernetes.io/managed-by" = "terraform"                               
        "purpose"                      = "data-plane"
      }                                                                                               
    }                     
  }                                                                                                   
                                                                                   
  # --- Inventory Service (Helm Release) ---
  resource "helm_release" "inventory" {
    name       = "inventory"    
    namespace  = kubernetes_namespace.control_plane.metadata[0].name
    chart      = "${path.module}/../helm/mini-tdmc-inventory"                                         
                                         
    set {                                                                                             
      name  = "replicaCount"                                                       
      value = "1"               
    }                                     
                                                                                                      
    set {                
      name  = "image.tag"                                                                             
      value = "latest"                                                             
    }                      
  }     
