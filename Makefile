BUILD_DIR = build
BINARY = ./keyctl

.PHONY: build install daemon-start daemon-stop test clean

build:
	@echo "No compile step needed (Python script)"

install: build
	install -d $(HOME)/.local/bin 2>/dev/null || install -d $(HOME)/bin || true
	cp $(BINARY) $(HOME)/.local/bin/keyctl 2>/dev/null || cp $(BINARY) $(HOME)/bin/keyctl 2>/dev/null || \
	echo "Install to your PATH manually or use install.sh"

daemon-start:
	@echo "Starting daemon... (requires KEYCTL_TOKEN set)"
	nohup $(BINARY) daemon --port 9099 > daemon.log 2>&1 &

daemon-stop:
	@echo "Stopping daemon..."
	pkill -f "$(BINARY) daemon" || true

test:
	python3 -m py_compile $(BINARY)
	./$(BINARY) --help
	bash tests/test_keyctl.sh

clean:
	rm -rf $(BUILD_DIR) daemon.log