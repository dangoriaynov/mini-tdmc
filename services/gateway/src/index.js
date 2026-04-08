               
  import { createYoga, createSchema } from 'graphql-yoga'                                            
  import { createServer } from 'node:http'
  import { stitchSchemas } from '@graphql-tools/stitch'                                              
  import { schemaFromExecutor } from '@graphql-tools/wrap'                         
  import { buildHTTPExecutor } from '@graphql-tools/executor-http'
                                                                                                     
  const INVENTORY_URL = process.env.INVENTORY_URL || 'http://localhost:4001/graphql'
                                                                                                     
  async function makeGatewaySchema() {                                                               
    // Create an executor that sends GraphQL requests to the Inventory Service                       
    const inventoryExecutor = buildHTTPExecutor({                                                    
      endpoint: INVENTORY_URL                                                      
    })                                              
                                               
    // Fetch the remote schema via introspection                                                     
    const inventorySchema = await schemaFromExecutor(inventoryExecutor)
                                                                                                     
    // Stitch schemas together — in real TDMC this would combine                   
    // multiple services (Inventory, Observer, Fleet Management)                                     
    return stitchSchemas({                                                                           
      subschemas: [                                                                                  
        {                                                                                            
          schema: inventorySchema,                                                 
          executor: inventoryExecutor                                                                
        }                                 
      ]                                                                                              
    })                                                                             
  }                                                                                                  
                                                                                   
  async function main() {                                                                            
    console.log(`Stitching schemas from: ${INVENTORY_URL}`)                                          
    const schema = await makeGatewaySchema()                                                         
    console.log('Schema stitching complete')                                                         
                                                                                   
    const yoga = createYoga({ schema })                                                              
    const server = createServer(yoga)                                              
                                          
    const port = process.env.PORT || 4000                                                            
    server.listen(port, () => {                     
      console.log(`Gateway running at http://localhost:${port}/graphql`)                             
    })                                                                             
  }                             
                                                    
  main().catch(err => {                        
    console.error('Failed to start gateway:', err.message)
    process.exit(1)                                                                                  
  })    
