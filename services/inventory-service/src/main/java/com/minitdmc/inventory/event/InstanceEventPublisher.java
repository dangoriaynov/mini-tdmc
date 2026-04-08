  package com.minitdmc.inventory.event;                                                              
                                             
  import com.minitdmc.inventory.model.ServiceInstance;                                               
  import org.slf4j.Logger;                                                                           
  import org.slf4j.LoggerFactory;
  import org.springframework.amqp.rabbit.core.RabbitTemplate;                                        
  import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;   
  import org.springframework.stereotype.Component;                                                   
                                                                                   
  @Component                                                                                         
  @ConditionalOnProperty(name = "rabbitmq.enabled", havingValue = "true", matchIfMissing = false)
  public class InstanceEventPublisher {                                                              
                           
      private static final Logger log = LoggerFactory.getLogger(InstanceEventPublisher.class);       
      private static final String EXCHANGE = "tdmc.tasks";                         
      private static final String ROUTING_KEY = "instance.create";
                                                                                                     
      private final RabbitTemplate rabbitTemplate;
                                                                                                     
      public InstanceEventPublisher(RabbitTemplate rabbitTemplate) {               
          this.rabbitTemplate = rabbitTemplate;
      }                                                                                              
                         
      public void publishCreateEvent(ServiceInstance instance) {                                     
          String message = String.format(                                          
              "{\"action\":\"CREATE\",\"instanceId\":\"%s\",\"name\":\"%s\",\"serviceType\":\"%s\",\"plan\":\"%s\"}",
              instance.getId(), instance.getName(), instance.getServiceType(), instance.getPlan()
          );                                                                                         
          rabbitTemplate.convertAndSend(EXCHANGE, ROUTING_KEY, message);           
          log.info("Published CREATE event for instance {} to {}/{}", instance.getId(), EXCHANGE,
  ROUTING_KEY);                          
      }                                   
  }   
