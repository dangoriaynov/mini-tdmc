import amqplib from 'amqplib'
import * as k8s from '@kubernetes/client-node'

const RABBITMQ_URL = process.env.RABBITMQ_URL || 'amqp://guest:guest@localhost:5672'
const NAMESPACE = process.env.TARGET_NAMESPACE || 'mini-tdmc-data-plane'
const QUEUE = 'tdmc.tasks.instance.create'

// Configure K8s client
const kc = new k8s.KubeConfig()
kc.loadFromCluster()
const customApi = kc.makeApiClient(k8s.CustomObjectsApi)

async function createPostgresInstanceCR(event) {
  const cr = {
    apiVersion: 'tdmc.tanzu.vmware.com/v1',
    kind: 'PostgresInstance',
    metadata: {
      name: `pgi-${event.instanceId.substring(0, 8)}`,
      namespace: NAMESPACE
    },
    spec: {
      name: event.name,
      serviceType: event.serviceType,
      plan: event.plan,
      instanceId: event.instanceId
    }
  }

  try {
    await customApi.createNamespacedCustomObject({
      group: 'tdmc.tanzu.vmware.com',
      version: 'v1',
      namespace: NAMESPACE,
      plural: 'postgresinstances',
      body: cr
    })
    console.log(`Created PostgresInstance CR: ${cr.metadata.name} in ${NAMESPACE}`)
  } catch (err) {
    if (err.statusCode === 409 || String(err).includes('AlreadyExists')) {
      console.log(`CR already exists: ${cr.metadata.name} (idempotent — skipping)`)
    } else {
      console.error(`Failed to create CR: ${err.message}`)
      throw err
    }
  }
}

async function main() {
  console.log(`Connecting to RabbitMQ: ${RABBITMQ_URL}`)
  const conn = await amqplib.connect(RABBITMQ_URL)
  const channel = await conn.createChannel()

  await channel.assertQueue(QUEUE, { durable: true })
  channel.prefetch(5)

  console.log(`Listening on queue: ${QUEUE}`)
  console.log(`Creating CRs in namespace: ${NAMESPACE}`)

  channel.consume(QUEUE, async (msg) => {
    if (!msg) return

    try {
      const event = JSON.parse(msg.content.toString())
      console.log(`Received event: ${event.action} for ${event.name}`)

      await createPostgresInstanceCR(event)
      channel.ack(msg)
      console.log(`Acknowledged message for ${event.name}`)
    } catch (err) {
      console.error(`Error processing message: ${err.message}`)
      channel.nack(msg, false, true)
    }
  })
}

main().catch(err => {
  console.error('Connector failed to start:', err.message)
  process.exit(1)
})
