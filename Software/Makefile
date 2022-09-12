.PHONY : all clean
all : 1x1conv_layer 3x3conv_layer 1x1conv_layer_simplified
%: %.c
	gcc -o $@ $<
clean:
	rm 1x1conv_layer 3x3conv_layer 1x1conv_layer_simplified


