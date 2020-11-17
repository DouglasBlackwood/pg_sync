FROM postgres:latest

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

# install pgtap on postgres database
RUN mkdir -p /docker-entrypoint-initdb.d
COPY ./initdb-pgtap.sql /docker-entrypoint-initdb.d/pgtap.sql


# pg_config --sharedir
# /usr/share/postgresql/9.6/extension/
