                                       
  package com.minitdmc.inventory.repository;                                                         
                             
  import com.minitdmc.inventory.model.ServiceInstance;                                               
  import org.springframework.stereotype.Repository;                                
                                                                                                     
  import java.util.ArrayList;
  import java.util.List;                                                                             
  import java.util.Map;                                                            
  import java.util.Optional;             
  import java.util.concurrent.ConcurrentHashMap;
                                                                                                     
  @Repository             
  public class InstanceRepository {                                                                  
      private final Map<String, ServiceInstance> store = new ConcurrentHashMap<>();
                         
      public List<ServiceInstance> findAll() {
          return new ArrayList<>(store.values());
      }                     
                                                                                                     
      public Optional<ServiceInstance> findById(String id) {
          return Optional.ofNullable(store.get(id));                                                 
      }                                                                            
                             
      public ServiceInstance save(ServiceInstance instance) {
          store.put(instance.getId(), instance);
          return instance;                                                                           
      }                   
                                                                                                     
      public boolean deleteById(String id) {                                       
          return store.remove(id) != null;
      }                      
  }                 
