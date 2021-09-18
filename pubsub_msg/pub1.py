def publish_messages(project_id, topic_id):
    """Publishes multiple messages to a Pub/Sub topic."""
    # [START pubsub_quickstart_publisher]
    # [START pubsub_publish]
    from google.cloud import pubsub_v1
    from avro.io import BinaryEncoder, DatumWriter
    import avro
    import io
    import json


    # TODO(developer)
    # project_id = "your-project-id"
    # topic_id = "your-topic-id"

    publisher = pubsub_v1.PublisherClient()
    # The `topic_path` method creates a fully qualified identifier
    # in the form `projects/{project_id}/topics/{topic_id}`
    topic_path = publisher.topic_path(project_id, topic_id)

    record = {"NameField": "Alaska", "GBSecField": 0}
    data = json.dumps(record).encode("utf-8")
    print(f"Preparing a JSON-encoded message:\n{data}")

    future = publisher.publish(topic_path, data)
    print(f"Published message ID: {future.result()}")

    for n in range(1, 1000):
        record = {"NameField": "lon{n}", "GBSecField": 1002+n}
        data = json.dumps(record).encode("utf-8")
        # When you publish a message, the client returns a future.
        future = publisher.publish(topic_path, data)
        print(future.result())

    print(f"Published messages to {topic_path}.")

project_id = "postgretrial"
topic_id = "collect_io_topic"

publish_messages(project_id, topic_id)
