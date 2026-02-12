FROM cypress/included:15.10.0

ADD . /e2e
WORKDIR /e2e/test-server
RUN cd /e2e/test-server && yarn
