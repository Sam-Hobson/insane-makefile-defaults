.DEFAULT_GOAL = help

# Usage example: echo '$(RED)RED TEXT$(RESET)'
RED    := \033[1;31m
GREEN  := \033[1;32m
YELLOW := \033[1;33m
BLUE   := \033[1;34m
RESET  := \033[0m

# Usage example:
# @$(call announce_step_interactive, "Connect to ssh session", { \
#     ssh root@127.0.0.1:5432; \
# })
define announce_interactive_step
	@{ \
		message=$$(echo $1); \
		echo "$(GREEN)>>> $$message$(RESET)"; \
		$2; \
		res=$$(echo $$?); \
		if [ $$res -eq 0 ]; then \
			echo "$(GREEN)>>> (END) $$message$(RESET)"; \
		else \
			echo "$(RED)>>> (END)($$res) $$message$(RESET)"; \
		fi; \
		echo; \
	}
endef

# Usage example:
# @$(call announce_step, "Saying hi!", { \
#     echo "hi"; \
# })
define announce_step
	@{ \
		message=$$(echo $1); \
		output=$$($2 2>&1); \
		res=$$(echo $$?); \
		if [ $$res -eq 0 ]; then \
			echo "$(GREEN)>>> $$message$(RESET)"; \
		else \
			echo "$(RED)>>> ($$res) $$message$(RESET)"; \
		fi; \
		echo $$output; \
		echo; \
	}
endef

# Usage example:
# $(eval ENV := $(shell $(call get_user_input,'Choose environment (dev/staging/prod)','dev staging prod')))
# @echo "Selected environment: $(ENV)"
define get_user_input
	{ \
		while true; do \
			read -p $(1) response; \
			for option in $$(echo $(2)); do \
				if [ "$$response" = "$$option" ]; then \
					echo $$response; \
					exit 0; \
				fi; \
			done; \
		done; \
	}
endef

assert_defined = \
	$(strip $(foreach 1,$1, \
		$(call __check_defined,$1,$(strip deployment environment))))

__check_defined = \
	$(if $(value $1),, \
		$(error Undefined $1$(if $2, ($2))))

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
	@$(call announce_interactive_step, "Cleaning up vimrc", {\
		deleteVimrc=$$($(call get_user_input, 'Delete vimrc? (y/n) ', 'y n')); \
		if [ "$$deleteVimrc" = "y" ]; then \
			rm ./vimrc; \
		fi; \
	})


MAKEFILE_PATH := $(realpath $(lastword $(MAKEFILE_LIST)))
help:  # Get help
	@awk '\
	BEGIN {\
		delete target_variables;\
		delete commands;\
		delete args;\
		delete desc;\
	}\
	{\
		# Check if this line defines a variable for a make target\
		if ($$0 ~ /^[a-zA-Z_][a-zA-Z0-9_-]*[[:space:]]*\?=/) {\
			target_variables[length(target_variables)] = $$1;\
		}  # Check if this line is a make target\
		else if ($$0 ~ /^[a-zA-Z_][a-zA-Z0-9_-]*:/) {\
			commands[length(commands)+1] = substr($$1, 1, length($$1) - 1);\
			desc[length(desc)+1] = substr($$0, index($$0, $$3));\
			\
			arg = "[";\
			num_variables = length(target_variables);\
			for (i = 0; i < num_variables; i++) {\
				arg = arg target_variables[i];\
				if (i < length(target_variables)-1) {\
					arg = arg ", ";\
				}\
			}\
			arg = arg "]";\
			args[length(args)+1] = arg;\
		}  # If this line is neither, delete all prefixed variables\
		else {\
			delete target_variables;\
		}\
	}\
	END {\
		num_commands = length(commands);\
		longest_command = 15;\
		longest_arg = 25;\
	    for (i = 0; i <= num_commands; i++) {\
			command_len = length(commands[i]);\
			if (command_len > longest_command) {\
				longest_command = command_len;\
			}\
			arg_len = length(args[i]);\
			if (arg_len > longest_arg) {\
				longest_arg = arg_len;\
			}\
		}\
		\
		print "make $(GREEN)[TARGET] $(YELLOW)[ARGS...]$(RESET)\n";\
	    printf "%-*s %-*s %s", longest_command, "Target", longest_arg, "Arguments", "Description";\
		\
		for (i = 0; i <= num_commands; i++) {\
			printf "$(GREEN)%-*s $(YELLOW)%-*s$(RESET) %s\n", longest_command, commands[i], longest_arg, args[i], desc[i];\
		}\
	}\
	' $(MAKEFILE_PATH)
