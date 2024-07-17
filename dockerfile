FROM public.ecr.aws/lambda/python:3.12

# Copy requirements.txt
COPY requirements.txt ${LAMBDA_TASK_ROOT}

# Install the specified packages
RUN pip install -r requirements.txt

# Copy function code
COPY ./monsternames.api/* ${LAMBDA_TASK_ROOT}

# Set handler for the lambda event
CMD [ "main.handler" ]