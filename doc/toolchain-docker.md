## Hackaday Superconference 2019 Badge Toolchain Docker Image

### Why?
Installing these tools in a Docker image means you don't have to install them on your local machine, which is probably weird because of all the other toolchains you've indiscriminately installed before. Stop the madness and keep things organized into useful containers. And compared to a virtual machine, you can edit your source files and do version control on your local machine, no need to worry about transferring files to a VM or sharing folders.
- Pros: Likely to work on any computer that runs Docker, no conflicts with existing setup. On macOS Catalina, this removes a major source of pain approving all the toolchain binaries before running.
- Cons: Not as easy to reach in and tweak the toolchain itself; if you need to do that, consider moving up to a full virtual machine.

### Building the image
While in this directory (`hadbadge2019_fpgasoc`) run the following command to create a "hadbadge" image with minimal Debian + ECP5 toolchain:
`./build_hadbadge_docker_image.sh`

### Launching a container
The badge codebase requires access to parent and peer directories when compiling various subprojects, so the docker command is a little tricky. It maps the PWD's parent and then shifts the working directory to the PWD. That means the container needs to be launched from within one of the application directories. Not too bad, since this is where you would run `make` anyway.

The tricky parts are wrapped in `badge_container.sh` which is a script to extract the top level and current PWD. The script requires `git` in order to determine the top-level directory of the repository we're in.

The `docker run` command line uses privileged mode, which should give it access to USB devices for flashing (not tested due to lack of access to hardware at the moment). It will launch the `hadbadge` image plus whatever commands you want to run inside the container. The command line above is made available in the parent directory for convenience, so the typical use case looks like this:
- Start in the `hadbadge2019_fpgasoc` directory
- `cd app-helloworld`
- `../badge_container.sh make`
This will launch a container, compile the source in the current directory, store output in the current directory, exit the container, and remove the container.
