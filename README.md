# Insane Makefile defaults!

This repository contains a Makefile template that's great for executing bash commands!
(It doesn't work so good for *making* things... Thank god Makefiles were never meant for that.)

## Features

### A great `make help` function
The default help function will grep the Makefile for make targets, associated variables/parameters
for the target, and a description of the target.

All these values will then be printed for all targets in a help message, making it easy to get a gauge
on the different make targets and how to use them.

Eg, in a Makefile with the following make target:
```bash
ip ?=
user ?=
ssh_dir ?= /home/test/.ssh
example_ssh:  # Open an ssh connection to the given host
	@$(call assert_defined, ip)
	@$(call assert_defined, user)
	@$(call assert_defined, ssh_dir)
	@$(call announce_interactive_step, "Connecting to ssh host", { \
		ssh -o BatchMode=yes $(user)@$(ip) true; \
		if [ $$? -eq 255 ]; then \
			known_hosts=$$(realpath "$(ssh_dir)/known_hosts"); \
			ssh-keygen -f "$$known_hosts" -R "$(ip)"; \
		fi; \
		ssh $(user)@$(ip); \
	})
	@$(call announce_step, "Retreiving .vimrc", scp $(user)@$(ip):/home/$(user)/.vimrc ./vimrc)
	@$(call announce_step, "Print the .vimrc", cat ./vimrc)
```

The help function will return:
```bash
> make
make [TARGET] [ARGS...]

Target          Arguments                 Description
example_ssh     [ip, user, ssh_dir]       Open an ssh connection to the given host
help            []                        Get help
```

### A suite of useful functions

#### The `assert_defined` function
This function makes it easy to assert that a user provided variable must be defined.

Eg:
```bash
ip ?=
example_ssh:  # Open an ssh connection to the given host
	@$(call assert_defined, ip)
```

#### The `announce_step` function
This will print out a message associated with the provided function,
and alter the output to emphasize errors received by the given function.

For example, for the code:
```bash
ip ?=
user ?=
example_target:
    @$(call announce_step, "Retreiving .vimrc from remote machine", scp $(user)@$(ip):/home/$(user)/.vimrc ./vimrc)
```

If the operation succeeds, the output will be:
```bash
> make example_ssh ip=127.0.0.1 user=root

>>> Retreiving .vimrc from remote machine
```
Not the output would be green if the return code is 0.

If the operation fails, the output could be:
```bash
> make example_ssh ip=127.0.0.1 user=root

(1) >>> Retreiving .vimrc from remote machine
ssh: connect to host 127.0.0.1 port 22: Connection refused
```
Not the output would be red if the return code is not 0.

#### The `announce_interactive_step` function
This is the same as the [announce_step](#the-announce_step-function) function, however it allows
for the provided function to route output directly back to the user, meaning it
works better for interactive commands such as `ssh` or `vim` for example.

