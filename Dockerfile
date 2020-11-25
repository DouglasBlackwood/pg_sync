FROM postgres:10

ENV POSTGRES_PASSWORD=postgres

RUN apt-get update \
    && apt-get install -y build-essential git-core libv8-dev curl postgresql-server-dev-$PG_MAJOR \
    && rm -rf /var/lib/apt/lists/*

# install pg_prove
RUN curl -LO http://xrl.us/cpanm \
    && chmod +x cpanm \
    && ./cpanm TAP::Parser::SourceHandler::pgTAP

# install pgtap
RUN git clone git://github.com/theory/pgtap.git \
    && cd pgtap \
    && make \
    && make install \
    && make clean

COPY ./sync.control /sync.control
RUN mv /sync.control $(pg_config --sharedir)/extension/sync.control
COPY ./sync--0.1.sql /sync--0.1.sql
RUN mv /sync--0.1.sql $(pg_config --sharedir)/extension/sync--0.1.sql

# install extensions
RUN mkdir -p /docker-entrypoint-initdb.d
COPY ./initdb-pgtap.sql /docker-entrypoint-initdb.d/pgtap.sql
