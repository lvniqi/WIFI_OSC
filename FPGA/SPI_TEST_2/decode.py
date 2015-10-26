def decode(a):
	regs = []
	print "address = ",hex(a[0]|a[7]&(0x80)>>7)
	for i in range(1,7):
		print "reg"+str(i)+" = "+hex(a[i]|((a[7]&(1<<(7-i)))>>(7-i)))
	for i in range(0,7):
		regs.append(hex(a[i]|((a[7]&(1<<(7-i)))>>(7-i))))
	return regs
