from google.cloud import pubsub_v1

# TODO(developer)
project_id = "postgretrial"
topic_id = "collect_io_topic"
subscription_id = "subscr_io"

publisher = pubsub_v1.PublisherClient()
subscriber = pubsub_v1.SubscriberClient()
topic_path = publisher.topic_path(project_id, topic_id)
subscription_path = subscriber.subscription_path(project_id, subscription_id)

# Wrap the subscriber in a 'with' block to automatically call close() to
# close the underlying gRPC channel when done.
with subscriber:
    subscription = subscriber.create_subscription(
        request={"name": subscription_path, "topic": topic_path}
    )

print(f"Subscription created: {subscription}")
