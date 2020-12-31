OUT_DIR=bin

all: build

build:
	mkdir -p $(OUT_DIR)
	crystal build --release ./src/tree.cr -o $(OUT_DIR)/tree

run:
	$(OUT_DIR)/tree

clean:
	rm -rf  $(OUT_DIR) .crystal .deps libs

