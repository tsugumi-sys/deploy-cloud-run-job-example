FROM python:3.11-slim

ARG MODULE_PATH_TO_EXECUTE
ENV MODULE_PATH_TO_EXECUTE=$MODULE_PATH_TO_EXECUTE
RUN echo $MODULE_PATH_TO_EXECUTE

COPY . /job

WORKDIR /job

RUN pip install --upgrade pip

ENV TZ=Asia/Tokyo

CMD python -m ${MODULE_PATH_TO_EXECUTE}
