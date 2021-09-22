from concurrent.futures._base import TimeoutError
from google.cloud.pubsublite.cloudpubsub import SubscriberClient
from google.cloud.pubsub import PubsubMessage
from google.cloud.pubsublite.types import (
    CloudRegion,
    CloudZone,
    FlowControlSettings,
    SubscriptionPath,
)

# TODO(developer):
# project_number = 1122334455
# cloud_region = "us-central1"
# zone_id = "a"
# subscription_id = "your-subscription-id"
# timeout = 90
project_number = "postgretrial"
subscription_id = "collect-light-subscr2"
cloud_region = "us-central1"
zone_id = "c"


location = CloudZone(CloudRegion(cloud_region), zone_id)
subscription_path = SubscriptionPath(project_number, location, subscription_id)
# Configure when to pause the message stream for more incoming messages based on the
# maximum size or number of messages that a single-partition subscriber has received,
# whichever condition is met first.
per_partition_flow_control_settings = FlowControlSettings(
    # 1,000 outstanding messages. Must be >0.
    messages_outstanding=1000,
    # 10 MiB. Must be greater than the allowed size of the largest message (1 MiB).
    bytes_outstanding=10 * 1024 * 1024,
)

def callback(message: PubsubMessage):
    message_data = message.data.decode("utf-8")
    metadata = MessageMetadata.decode(message.message_id)
    print(f"Received {message_data} of ordering key {message.ordering_key} with id {metadata}.")
    message.ack()

# SubscriberClient() must be used in a `with` block or have __enter__() called before use.
with SubscriberClient() as subscriber_client:

    streaming_pull_future = subscriber_client.subscribe(
        subscription_path,
        callback=callback,
        per_partition_flow_control_settings=per_partition_flow_control_settings,
    )

    print(f"Listening for messages on {str(subscription_path)}...")

    try:
        streaming_pull_future.result(timeout=timeout)
    except TimeoutError or KeyboardInterrupt:
        streaming_pull_future.cancel()
        assert streaming_pull_future.done()