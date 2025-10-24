# Build-Stufe nur für Renku-CLI-Exactversion
FROM renku/renkulab-r:4.3.1-0.25.0 as builder

ARG RENKU_VERSION=2.9.4
RUN if [ -n "$RENKU_VERSION" ] ; then \
      source .renku/venv/bin/activate ; \
      cur=$(renku --version) ; \
      if [ "$RENKU_VERSION" != "$cur" ] ; then \
        pip uninstall renku -y ; \
        pip install --no-cache-dir --force renku==${RENKU_VERSION} ; \
      fi ; \
    fi

# Laufzeit-Image
FROM renku/renkulab-r:4.3.1-0.25.0

ARG DEBIAN_FRONTEND=noninteractive
USER root

# Locale/Zeit
ENV TZ=Europe/Zurich \
    LANG=de_CH.UTF-8 \
    LANGUAGE=de_CH:de \
    LC_ALL=de_CH.UTF-8

RUN apt-get update && apt-get install -y --no-install-recommends \
      locales tzdata libxml2-dev \
    && rm -rf /var/lib/apt/lists/* \
 && echo "de_CH.UTF-8 UTF-8" >> /etc/locale.gen \
 && locale-gen de_CH.UTF-8 \
 && dpkg-reconfigure --frontend=noninteractive locales \
 && update-locale LANG=de_CH.UTF-8

USER ${NB_USER}

# Repos-Snapshot für reproduzierbare R-Pakete
ENV RSPM_DATE=2025-04-01
RUN echo "r <- getOption('repos'); r['CRAN'] <- 'https://packagemanager.rstudio.com/cran/__linux__/jammy/${RSPM_DATE}'; options(repos = r)" > ~/.Rprofile

# Projekt rein + Pakete installieren
COPY --chown=${NB_USER}:${NB_USER} . ${HOME}/
RUN R -f ${HOME}/install.R

# Exakte Renku-CLI übernehmen
COPY --from=builder --chown=${NB_USER}:${NB_USER} ${HOME}/.renku/venv ${HOME}/.renku/venv
