def publish_messages(project_id, topic_id):
    """Publishes multiple messages to a Pub/Sub topic."""
    # [START pubsub_quickstart_publisher]
    # [START pubsub_publish]

    from avro.io import BinaryEncoder, DatumWriter
    import avro
    import io
    import json
    from google.cloud.pubsublite.cloudpubsub import PublisherClient
    from google.cloud.pubsublite.types import (
        CloudRegion,
        CloudZone,
        MessageMetadata,
        TopicPath,
    )


    # TODO(developer)
    # project_id = "your-project-id"
    # topic_id = "your-topic-id"

    publisher = PublisherClient()
    # The `topic_path` method creates a fully qualified identifier
    # in the form `projects/{project_id}/topics/{topic_id}`
    #topic_path = publisher.topic_path(project_id, topic_id)
    cloud_region = "us-central1"
    zone_id="us-central1-c"

    location = CloudZone(CloudRegion(cloud_region), zone_id)
    topic_path = TopicPath(project_id, location, topic_id)

    record = {"NameField": "Alaska", "GBSecField": 0}
    data = json.dumps(record).encode("utf-8")
    #future = publisher.publish(topic_path, data)

    print(f"Published message ID: {future.result()}")

    future = publisher.publish(
        topic_path, "data", year="2020", author="unknown",
    )
##    for n in range(1, 1000):
##        record = {"NameField": f"lon{n}", "GBSecField": 10000+n}
##        data = json.dumps(record).encode("utf-8")
        # When you publish a message, the client returns a future.
##        future = publisher.publish(topic_path, data)
##        print(future.result())

    print(f"Published messages to {topic_path}.")

project_id = "postgretrial"
topic_id = "collect-light-topic"

publish_messages(project_id, topic_id)
