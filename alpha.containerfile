FROM docker.io/library/alpine:edge

ARG NAME
ARG UIDN

LABEL name=$NAME
LABEL description="Development Environmant"
LABEL maintainer="Nero Dicentra <nero@asgard.id>"

ENV GOPRIVATE="github.com/cetorion"
ENV CGO_ENABLED="0"
ENV GOPATH="/home/$UIDN/.go"
ENV HOSTNAME=$NAME

RUN <<-'EOF'
	apk upgrade -U --no-cache
	apk add --no-cache \
	go git curl tmux nodejs yarn sudo helix shfmt tzdata \
	python3 py3-pip openssh-client gpg gpg-agent pinentry-tty \
	aws-cli nushell podman jq yq-go zip ansible carapace ruff starship
EOF

RUN <<-'EOF'
	adduser -D $UIDN -s /usr/bin/nu
	addgroup $UIDN wheel
	mkdir -p /etc/sudoers.d && echo '%wheel ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/nopass
	echo $NAME > /etc/hostname
	mkdir -p /data && chown -R $UIDN:$UIDN /data
  ln -sf /usr/share/zoneinfo/Australia/Sydney /etc/localtime
EOF

WORKDIR /home/$UIDN

COPY data/gnupg .gnupg
COPY data/helix .config/helix
COPY data/home/tmux.conf .tmux.conf
COPY data/home/gitconfig .gitconfig
COPY data/nushell/config.nu .config/nushell/config.nu
COPY data/ssh .ssh

RUN <<-EOF
	mkdir -p .ssh && ssh-keygen -t ed25519 -N "" -q -f .ssh/id_ed25519
	chmod 700 .gnupg
	chown -R $UIDN:$UIDN /home/$UIDN
	chmod u+s /usr/bin/newuidmap /usr/bin/newgidmap
EOF

USER $UIDN

RUN yarn global add \
prettier bash-language-server typescript-language-server \
vscode-css-languageservice yaml-language-server
	
RUN <<-EOF
	go install golang.org/x/tools/gopls@latest
	go install github.com/go-delve/delve/cmd/dlv@latest
	go install golang.org/x/tools/cmd/goimports@latest
	go install github.com/golangci/golangci-lint/v2/cmd/golangci-lint@latest
EOF

RUN <<-EOF
	nu -c 'mkdir ($nu.data-dir | path join "vendor/autoload")'
	nu -c 'starship init nu | save -f ($nu.data-dir | path join "vendor/autoload/starship.nu")'
	nu -c '$nu.user-autoload-dirs | each {|e|  mkdir $e}'
EOF

ENTRYPOINT ["/usr/bin/nu", "-i", "-l"]
