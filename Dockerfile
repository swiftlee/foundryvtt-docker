ARG CREATED_TIMESTAMP=unspecified
ARG FOUNDRY_PASSWORD
ARG FOUNDRY_RELEASE_URL
ARG FOUNDRY_USERNAME
ARG FOUNDRY_VERSION=0.6.3
ARG GIT_COMMIT=unspecified
ARG GIT_REMOTE=unspecified
ARG VERSION

FROM node:12-alpine as optional-release-stage

ARG FOUNDRY_PASSWORD
ARG FOUNDRY_RELEASE_URL
ARG FOUNDRY_USERNAME
ARG FOUNDRY_VERSION
ENV ARCHIVE="foundryvtt-${FOUNDRY_VERSION}.zip"

WORKDIR /root
COPY src/package.json src/authenticate.js ./
# .placeholder file to mitigate https://github.com/moby/moby/issues/37965
RUN mkdir dist && touch dist/.placeholder
RUN if [ -n "${FOUNDRY_USERNAME}" ] && [ -n "${FOUNDRY_PASSWORD}" ]; then \
  npm install && \
  s3_url=$(./authenticate.js "${FOUNDRY_USERNAME}" "${FOUNDRY_PASSWORD}" "${FOUNDRY_VERSION}") && \
  wget -O ${ARCHIVE} "${s3_url}" && \
  unzip -d dist ${ARCHIVE} 'resources/*'; \
  elif [ -n "${FOUNDRY_RELEASE_URL}" ]; then \
  wget -O ${ARCHIVE} "${FOUNDRY_RELEASE_URL}" && \
  unzip -d dist ${ARCHIVE} 'resources/*'; \
  fi

RUN wget https://get.5e.tools/plutonium/plutonium.zip && \
  unzip plutonium.zip -d dist -q

FROM node:12-alpine as final-stage

ARG CREATED_TIMESTAMP=unspecified
ARG FOUNDRY_UID=421
ARG FOUNDRY_VERSION
ARG GIT_COMMIT
ARG GIT_REMOTE
ARG TARGETPLATFORM
ARG VERSION

LABEL com.foundryvtt.version=${FOUNDRY_VERSION}
LABEL org.opencontainers.image.authors="markf+github@geekpad.com"
LABEL org.opencontainers.image.created=${CREATED_TIMESTAMP}
LABEL org.opencontainers.image.licenses="CC0-1.0"
LABEL org.opencontainers.image.revision=${GIT_COMMIT}
LABEL org.opencontainers.image.source=${GIT_REMOTE}
LABEL org.opencontainers.image.title="Foundry Virtual Tabletop"
LABEL org.opencontainers.image.vendor="Geekpad"
LABEL org.opencontainers.image.version=${VERSION}

ENV FOUNDRY_HOME="/home/foundry"
ENV FOUNDRY_VERSION=${FOUNDRY_VERSION}

RUN addgroup --system --gid ${FOUNDRY_UID} foundry \
  && adduser --system --uid ${FOUNDRY_UID} --ingroup foundry foundry

RUN apk --update --no-cache add jq su-exec

WORKDIR ${FOUNDRY_HOME}

COPY --from=optional-release-stage /root/dist/ .
COPY src/entrypoint.sh src/package.json src/set_password.js src/authenticate.js src/plut_mod.js ./
RUN npm install && echo ${VERSION} > image_version.txt

VOLUME ["/data"]

EXPOSE 30000/tcp
ENTRYPOINT ["./entrypoint.sh"]
CMD ["resources/app/main.js", "--port=30000", "--headless", "--dataPath=/data"]
