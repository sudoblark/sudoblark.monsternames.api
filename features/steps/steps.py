import json

from requests import post
from behave import *
from asserts import assert_equal


@given("payload fields {fields}")
def step_impl(context, fields):
    context.fields = fields.split(",")


@given("payload values {values}")
def step_impl(context, values):
    context.values = values.split(",")


@then("I should be able to POST")
def step_impl(context):
    payload = {}
    for index in range(len(context.fields)):
        payload[context.fields[index - 1]] = context.values[index - 1]

    body = {"path": context.path, "httpMethod": "POST", "Body": json.dumps(payload)}

    request = post(context.base_url, json=json.dumps(body), timeout=10)
    assert_equal(request.status_code, 200)


@then("GET will contain all fields")
def step_impl(context):
    body = {"path": context.path, "httpMethod": "GET"}
    request = post(context.base_url, json=json.dumps(body), timeout=10)

    assert_equal(request.status_code, 200)

    response_body = json.loads(json.loads(request.text)["body"])
    print(response_body.keys())
    print(context.fields)

    field_list = context.fields + ["full_name"]

    for field in field_list:
        assert_equal(field in response_body.keys(), True)
