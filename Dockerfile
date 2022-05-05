FROM postgres:13

ENV POSTGRES_PASSWORD=postgres

RUN apt-get update \
    && apt-get install -y \
        build-essential git-core libv8-dev curl postgresql-server-dev-$PG_MAJOR \
        python3-pip postgresql-plpython3-$PG_MAJOR pgxnclient \
    && rm -rf /var/lib/apt/lists/*

# install faker
RUN pip install faker
RUN pgxn install postgresql_faker

# install pg_prove
RUN curl -LO http://xrl.us/cpanm \
    && chmod +x cpanm \
    && ./cpanm TAP::Parser::SourceHandler::pgTAP

# install pgtap
RUN pgxn install pgtap

# copy source files
COPY ./sync.control /sync.control
RUN mv /sync.control $(pg_config --sharedir)/extension/sync.control
COPY ./sync--0.1.sql /sync--0.1.sql
RUN mv /sync--0.1.sql $(pg_config --sharedir)/extension/sync--0.1.sql

# install extensions and create user
RUN mkdir -p /docker-entrypoint-initdb.d
COPY ./initdb-extension.sql /docker-entrypoint-initdb.d/extension.sql
COPY ./initdb-user.sql /docker-entrypoint-initdb.d/user.sql
