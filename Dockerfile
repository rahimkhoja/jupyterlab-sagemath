# Build Command
# sudo docker kill $(sudo docker ps -q);  sudo docker rm $(sudo docker ps -a -q); sudo docker rmi $(sudo docker images -q); sudo docker build --squash --no-cache -t rahimtagchangemme/jupyterhub:jupyterlab-sage .

ARG BASE_CONTAINER=jupyter/datascience-notebook
FROM $BASE_CONTAINER

LABEL maintainer="Rahim Khoja <rahim@khoja.ca>"

USER root

# Update System Packages for SageMath
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    dvipng \
    ffmpeg \
    imagemagick \
    texlive \
    tk tk-dev \
    jq && \
    ldconfig && \
    apt-get autoclean && \
    apt-get clean && \
    apt-get autoremove

USER jovyan

# Install Conda Packages (Plotly, SageMath)
RUN conda create --yes -n sage sage python=3.9 && \
    conda install --yes "jupyterlab>=3" "ipywidgets>=7.6" && \
    conda install --yes -c conda-forge -c plotly jupyter-dash && \
    conda install --yes -c conda-forge jupyterlab-drawio && \
    conda install -c conda-forge jupyterlab-spellchecker --yes && \
    conda clean --yes --all

RUN pip install nbgitpuller && \
    pip install jupyterlab-git && \
    pip install jupytext --upgrade && \
    pip install jupyterlab-system-monitor && \
    pip install lckr-jupyterlab-variableinspector && \
    pip install ipywidgets

RUN npm cache clean --force && \
    fix-permissions $CONDA_DIR && \
    fix-permissions /home/jovyan

RUN jupyter labextension install jupyterlab-plotly \
  && jupyter labextension install @jupyter-widgets/jupyterlab-manager plotlywidget \
  && jupyter labextension install @techrah/text-shortcuts \
  && jupyter serverextension enable nbgitpuller --sys-prefix \
  && jupyter lab build

USER root

ENV SAGE_ROOT=/opt/conda/envs/sage/

RUN /opt/conda/envs/sage/bin/sage -c "install_scripts('/usr/local/bin')" && \
    ln -s "/opt/conda/envs/sage/bin/sage" /usr/bin/sage && \
    ln -s /usr/bin/sage /usr/bin/sagemath

RUN jupyter kernelspec install $(/opt/conda/envs/sage/bin/sage -sh -c 'ls -d /opt/conda/envs/sage/share/jupyter/kernels/sagemath'); exit 0

RUN chown -R jovyan:users /home/jovyan && \
    chmod -R 0777 /home/jovyan && \
    rm -rf /home/jovyan/*

USER jovyan

ENV HOME=/home/jovyan

ENV PIPELINE=github-actions

WORKDIR $HOME