                                                                   
  package com.minitdmc.inventory.controller;
                                                                                                     
  import com.minitdmc.inventory.event.InstanceEventPublisher;
  import com.minitdmc.inventory.model.ServiceInstance;                                               
  import com.minitdmc.inventory.repository.InstanceRepository;                     
  import org.springframework.graphql.data.method.annotation.Argument;
  import org.springframework.graphql.data.method.annotation.MutationMapping;
  import org.springframework.graphql.data.method.annotation.QueryMapping;                            
  import org.springframework.stereotype.Controller;
                                                                                                     
  import java.util.List;                                                           
  import java.util.Map;    
  import java.util.Optional;                                                                         
                             
  @Controller                                                                                        
  public class InstanceController {                                                
                                                                                                     
      private final InstanceRepository repository;
      private final Optional<InstanceEventPublisher> eventPublisher;                                 
                                                                                   
      public InstanceController(InstanceRepository repository, Optional<InstanceEventPublisher>      
  eventPublisher) {         
          this.repository = repository;                                                              
          this.eventPublisher = eventPublisher;                                    
      }             
                         
      @QueryMapping                      
      public List<ServiceInstance> instances() {
          return repository.findAll();
      }                                                                                              
                                          
      @QueryMapping                                                                                  
      public ServiceInstance instance(@Argument String id) {                       
          return repository.findById(id).orElse(null);
      }                                  
                           
      @MutationMapping                                                                               
      public ServiceInstance createInstance(@Argument Map<String, String> input) {
          ServiceInstance instance = new ServiceInstance(                                            
              input.get("name"),                                                   
              input.get("serviceType"),
              input.get("plan")
          );                    
          repository.save(instance);      
          eventPublisher.ifPresent(pub -> pub.publishCreateEvent(instance));                         
          return instance;
      }                                                                                              
                                                                                   
      @MutationMapping     
      public boolean deleteInstance(@Argument String id) {                                           
          return repository.deleteById(id);
      }                                                                                              
  }        
