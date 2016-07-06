FROM drewcrawford/swift:latest
RUN apt-get update && apt-get install --no-install-recommends curl ca-certificates -y
RUN curl -s -L https://packagecloud.io/install/repositories/anarchytools/AT/script.deb.sh  | bash
RUN apt-get install atbuild -y
