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
	&& apt-get clean && rm -rf /var/lib/apt/lists/*

WORKDIR /

# Setup users.
RUN echo 'root:changeme' | chpasswd

# Setup sshd.
RUN sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config && \
	sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config
RUN service ssh start

# Setup git.
RUN git config --global init.defaultBranch main && \
	git config --global --add safe.directory /var/git/*

# Setup cgit.
COPY ./cgit/apache.conf /etc/apache2/conf-available/cgit.conf
COPY ./cgit/cgitrc /etc/cgitrc
RUN a2enconf cgit && \
	a2enmod cgid

# Copy management scripts.
COPY ./git-scripts /

# Set exposed ports.
EXPOSE 22 80

# Copy the entrypoint script and set it.
COPY ./entrypoint.sh /bin/entrypoint.sh
ENTRYPOINT ["/bin/entrypoint.sh"]
