def before_all(context):
    context.base_url = "http://127.0.0.1:9000/2015-03-31/functions/function/invocations"


def before_scenario(context, scenario):
    context.path = scenario.name.split(" ")[0]
