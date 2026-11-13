"""Domain objects: pure, I/O-free value types that own the API's invariants.

Objects here import nothing from the other layers: no boto3, no repository,
and no table or wire formats. Repositories depend on these, never the reverse.
"""
