                                                                                                
  package com.minitdmc.inventory.model;                                            
                                                                                                     
  import java.time.Instant;                                                                          
  import java.util.UUID;     
                                                                                                     
  public class ServiceInstance {                                                   
      private String id;                                                                             
      private String name;                                                                           
      private String serviceType;                                                                    
      private String plan;                                                                           
      private String status;                                                                         
      private String createdAt;          
                                                                                                     
      public ServiceInstance() {}                                                  
                          
      public ServiceInstance(String name, String serviceType, String plan) {
          this.id = UUID.randomUUID().toString();
          this.name = name;
          this.serviceType = serviceType;
          this.plan = plan;     
          this.status = "PENDING";
          this.createdAt = Instant.now().toString();                                                 
      }                                   
                                                                                                     
      public String getId() { return id; }                                         
      public void setId(String id) { this.id = id; }
      public String getName() { return name; }
      public void setName(String name) { this.name = name; }
      public String getServiceType() { return serviceType; }                                         
      public void setServiceType(String serviceType) { this.serviceType = serviceType; }
      public String getPlan() { return plan; }                                                       
      public void setPlan(String plan) { this.plan = plan; }                       
      public String getStatus() { return status; }
      public void setStatus(String status) { this.status = status; }
      public String getCreatedAt() { return createdAt; }
      public void setCreatedAt(String createdAt) { this.createdAt = createdAt; }
  }       
