FROM amazoncorretto:18 AS base
# RUN useradd -M user && \
#     mkdir -p /app && \
#     chown -R user:user /app
RUN mkdir -p /app && \
    chown -R 1000:1000 /app
WORKDIR /app
# USER user
USER 1000
# # RUN apk --no-cache add curl wget
# # 
# # # ENV PORT 80
# # # EXPOSE 80
# # # HEALTHCHECK --timeout=5s --start-period=5s --retries=1 \
# # #     CMD curl -f http://localhost:$PORT/health_check
# # RUN wget -O /tmp/jmx_prometheus_javaagent.jar https://repo1.maven.org/maven2/io/prometheus/jmx/jmx_prometheus_javaagent/0.15.0/jmx_prometheus_javaagent-0.15.0.jar;
# ENTRYPOINT [ "/bin/sh", "-c", ">"]
# CMD [ "java", "${JAVA_OPTS}", "-javaagent:/tmp/jmx_prometheus_javaagent.jar=9090:/tmp/metrics-configs/config.yml", \
#     "-Djava.security.egd=file:/dev/./urandom-jar", "-jar", "/app/app.jar", "-Dspring.profiles.active=${SPRING_PROFILE}", \
#     "${PARAMS}", "${EXTRA_PARAMS}" ]
ENTRYPOINT [ "/bin/sh", "-c", "java ${JAVA_OPTS} -Djava.security.egd=file:/dev/./urandom-jar -jar /app/app.jar -Dspring.profiles.active=${SPRING_PROFILE} ${PARAMS} ${EXTRA_PARAMS}" ]

FROM gradle:7.5-jdk18 AS build
WORKDIR /app

FROM build AS cache
ENV GRADLE_USER_HOME /cache
COPY build.gradle gradle.properties settings.gradle /app/
RUN gradle clean build --no-daemon > /dev/null 2>&1 || true

FROM build AS builder
COPY --from=cache /cache /home/gradle/.gradle
COPY . /app/.
RUN gradle clean build --no-daemon

FROM base
COPY --from=builder --chown=1000:1000 /app/build/libs/*SNAPSHOT.jar /app/app.jar
