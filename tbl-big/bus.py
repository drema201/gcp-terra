##https://googleapis.dev/python/bigtable/latest/data-api.html

from google.cloud import bigtable
client = bigtable.Client(admin=True)

instance = client.instance("bus-instance")
# instance.reload()

table = instance.table("bus-data")
column_families = table.list_column_families()
print(column_families)

rowKey = "MTA/M86-SBS/1496275200000/NYCT_5824"
row_data = table.read_row(rowKey)
print(row_data.cells)

print(row_data.cells[:][:][0])
