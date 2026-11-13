"""Repositories: collection-like access to the API's own data, over DynamoDB.

Each repository takes its boto3 tables, so tests can pass mocked ones, keeps
the raw items to itself, and returns domain objects built by the mappers.
"""
