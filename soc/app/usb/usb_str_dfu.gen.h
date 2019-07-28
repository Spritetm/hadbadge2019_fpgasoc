static const struct usb_str_desc _str0_desc = {
	.bLength		= 4,
	.bDescriptorType	= USB_DT_STR,
	.wString		= { 0x0409 },
};

static const struct usb_str_desc _str1_desc = {
	.bLength		= 34,
	.bDescriptorType	= USB_DT_STR,
	.wString		= {
		0x0030, 0x0030, 0x0030, 0x0030, 0x0030, 0x0030, 0x0030, 0x0030,
		0x0030, 0x0030, 0x0030, 0x0030, 0x0030, 0x0030, 0x0030, 0x0030,
	},
};

static const struct usb_str_desc _str2_desc = {
	.bLength		= 16,
	.bDescriptorType	= USB_DT_STR,
	.wString		= {
		0x006f, 0x0073, 0x006d, 0x006f, 0x0063, 0x006f, 0x006d,
	},
};

static const struct usb_str_desc _str3_desc = {
	.bLength		= 46,
	.bDescriptorType	= USB_DT_STR,
	.wString		= {
		0x0069, 0x0043, 0x0045, 0x0034, 0x0030, 0x0020, 0x0055, 0x0053,
		0x0042, 0x0020, 0x0044, 0x0065, 0x0076, 0x0069, 0x0063, 0x0065,
		0x0020, 0x0028, 0x0044, 0x0046, 0x0055, 0x0029,
	},
};

static const struct usb_str_desc _str4_desc = {
	.bLength		= 8,
	.bDescriptorType	= USB_DT_STR,
	.wString		= {
		0x0044, 0x0046, 0x0055,
	},
};

static const struct usb_str_desc _str5_desc = {
	.bLength		= 32,
	.bDescriptorType	= USB_DT_STR,
	.wString		= {
		0x0069, 0x0043, 0x0045, 0x0034, 0x0030, 0x0020, 0x0062, 0x0069,
		0x0074, 0x0073, 0x0074, 0x0072, 0x0065, 0x0061, 0x006d,
	},
};

static const struct usb_str_desc _str6_desc = {
	.bLength		= 32,
	.bDescriptorType	= USB_DT_STR,
	.wString		= {
		0x0052, 0x0049, 0x0053, 0x0043, 0x002d, 0x0056, 0x0020, 0x0066,
		0x0069, 0x0072, 0x006d, 0x0077, 0x0061, 0x0072, 0x0065,
	},
};

static const struct usb_str_desc * const _str_desc_array[] = {
	& _str0_desc,
	& _str1_desc,
	& _str2_desc,
	& _str3_desc,
	& _str4_desc,
	& _str5_desc,
	& _str6_desc,
};
