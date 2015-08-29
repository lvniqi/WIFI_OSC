obj-${CONFIG_GPIO_interrupt}	+= gpio_interrupt.o
obj-m := gpio_interrupt.o
all: modules
modules:
	$(MAKE) ARCH=$(ARCH)  CROSS_COMPILE=$(CROSS_COMPILE)  -C $(KSRC)  M=$(shell pwd)  modules
clean:
	rm $(shell pwd)/*.ko
	rm $(shell pwd)/*.o
	rm $(shell pwd)/*.mod.c
	rm $(shell pwd)/Module.symvers
	rm $(shell pwd)/modules.order
