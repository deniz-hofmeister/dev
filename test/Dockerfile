FROM ros:humble-ros-core

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    xz-utils \
    git \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

ENV USER=root
ENV NIX_INSTALLER_NO_MODIFY_PROFILE=1
RUN curl -L https://nixos.org/nix/install | sh -s -- --daemon --yes

RUN echo "source /opt/ros/humble/setup.bash" >> ~/.bashrc && \
    echo ". /nix/var/nix/profiles/default/etc/profile.d/nix.sh" >> ~/.bashrc

WORKDIR /workspace
COPY . /workspace

RUN . /nix/var/nix/profiles/default/etc/profile.d/nix.sh && \
    nix build --extra-experimental-features "nix-command flakes" .

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    cmake \
    python3-colcon-common-extensions && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

RUN . /opt/ros/humble/setup.sh && \
    mkdir src && \
    mv test/ros2_cpp_pkg src/ && \
    mv test/ros2_py_pkg src/ && \
    colcon build --symlink-install && \
    echo "source /workspace/install/setup.bash" >> ~/.bashrc

RUN . /opt/ros/humble/setup.sh && \
    cd src/ros2_cpp_pkg && \ 
    mkdir build && \ 
    cd build && \
    cmake -DCMAKE_EXPORT_COMPILE_COMMANDS=1 -DCMAKE_BUILD_TYPE=Debug .. && \
    make

RUN ln -s src/ros2_cpp_pkg/build/compile_commands.json compile_commands.json

RUN . /nix/var/nix/profiles/default/etc/profile.d/nix.sh && \
    echo 'alias nv="nix run --extra-experimental-features \"nix-command flakes\" --refresh github:deniz-hofmeister/dev#neovim"' >> ~/.bashrc && \
    echo 'alias zsh="nix run --extra-experimental-features \"nix-command flakes\" --refresh github:deniz-hofmeister/dev#zsh"' >> ~/.bashrc

CMD ["/bin/bash"]
