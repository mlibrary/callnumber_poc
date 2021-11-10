FROM ruby:3.0.1

#Set up variables for creating a user to run the app in the container
ARG UID
ARG GID
ARG UNAME=app
ENV APP_HOME /app
ENV BUNDLE_PATH /bundle

#Create the group for the user
RUN if [ x"${GID}" != x"" ] ; \
    then groupadd ${UNAME} -g ${GID} -o ; \
    else groupadd ${UNAME} ; \
    fi

#Create the User and assign ${APP_HOME} as its home directory
RUN if [ x"${UID}" != x"" ] ; \
    then  useradd -m -d ${APP_HOME} -u ${UID} -o -g ${UNAME} -s /bin/bash ${UNAME} ; \
    else useradd -m -d ${APP_HOME} -g ${UNAME} -s /bin/bash ${UNAME} ; \
    fi

WORKDIR $APP_HOME

RUN mkdir -p ${BUNDLE_PATH} ${APP_HOME}/public ${APP_HOME}/tmp && chown -R ${UNAME} ${BUNDLE_PATH} ${APP_HOME}/public ${APP_HOME}/tmp

RUN gem install bundler

USER $UNAME

COPY --chown=${UNAME}:${UNAME} Gemfile* ${APP_HOME}/
RUN bundle install

COPY --chown=${UNAME}:${UNAME} . ${APP_HOME}

ARG BIND_IP=0.0.0.0
ARG BIND_PORT=3000
ARG RAILS_ENV=development

ENV RAILS_ENV=${RAILS_ENV} \
    BIND_IP=${BIND_IP} \
    BIND_PORT=${BIND_PORT}

CMD bundle exec rails s -b ${BIND_IP} -p ${BIND_PORT}
