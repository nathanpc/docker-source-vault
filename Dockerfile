FROM debian:12

# Install all the required software.
RUN apt update && apt install -y \
	openssh-server \
	git \
	python3-markdown \
	python3-docutils \
	python3-pygments \
	groff \
	apache2 \
	cgit \
	vim \
	sudo \
	supervisor \
	&& apt-get clean && rm -rf /var/lib/apt/lists/*

WORKDIR /
ENV SOURCE_VAULT_CONTAINER 1

# Setup users.
COPY ./credentials.sh /credentials.sh
RUN chmod +x /credentials.sh && /credentials.sh && rm /credentials.sh

# Setup sshd.
RUN sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config && \
	sed -i 's/#PubkeyAuthentication yes/PubkeyAuthentication yes/' /etc/ssh/sshd_config && \
	sed -i -E 's/#AuthorizedKeysFile\s+\.ssh\/authorized_keys/AuthorizedKeysFile\t.ssh\/authorized_keys \/etc\/ssh\/authorized_keys/' /etc/ssh/sshd_config
COPY ./ssh/ssh_host_* /etc/ssh
RUN service ssh start
COPY ./ssh/ssh_host_ed25519_key /root/.ssh/id_ed25519
COPY ./ssh/ssh_host_ed25519_key.pub /root/.ssh/id_ed25519.pub

# Setup git.
RUN git config --global init.defaultBranch main && \
	git config --global --add safe.directory /var/git/*

# Setup cgit.
COPY ./cgit/apache.conf /etc/apache2/conf-available/cgit.conf
COPY ./cgit/cgitrc /etc/cgitrc
RUN a2enconf cgit && \
	a2enmod cgid

# Copy management scripts.
COPY ./git-scripts/* /git-scripts/
COPY ./crontab /etc/cron.d/vault
COPY ./supervisord.conf /etc/supervisor/supervisord.conf

# Set exposed ports and run the supervisor.
EXPOSE 22 80
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/supervisord.conf", "-n"]
