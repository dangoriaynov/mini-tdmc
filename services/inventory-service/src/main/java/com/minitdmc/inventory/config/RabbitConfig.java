                                                                                                
  package com.minitdmc.inventory.config;
                                                                                                     
  import org.springframework.amqp.core.Binding;                                    
  import org.springframework.amqp.core.BindingBuilder;                                               
  import org.springframework.amqp.core.Queue;                                                        
  import org.springframework.amqp.core.TopicExchange;
  import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;                     
  import org.springframework.context.annotation.Bean;                              
  import org.springframework.context.annotation.Configuration;                                       
                            
  @Configuration                                                                                     
  @ConditionalOnProperty(name = "rabbitmq.enabled", havingValue = "true", matchIfMissing = false)
  public class RabbitConfig {            
                           
      @Bean                                                                                          
      public TopicExchange taskExchange() {
          return new TopicExchange("tdmc.tasks");                                                    
      }                                                                                              
                         
      @Bean                                                                                          
      public Queue createInstanceQueue() {                                         
          return new Queue("tdmc.tasks.instance.create", true);
      }                                                                                              
                            
      @Bean                                                                                          
      public Binding binding(Queue createInstanceQueue, TopicExchange taskExchange) {
          return BindingBuilder.bind(createInstanceQueue)
              .to(taskExchange)
              .with("instance.create");
      }                         
  }   
