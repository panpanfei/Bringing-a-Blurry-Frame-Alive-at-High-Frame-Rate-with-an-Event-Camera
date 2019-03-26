# -*- coding: utf-8 -*-

""" 
input is a device name
output is the device address space. 
For vision sensors this is typically a tuple of [X Y], but the DAS1 for
example, has four address dimensions. 
"""

def DeviceAddressSpace(deviceName):

    devices = {
			'Dvs128':			   [128, 128], 
			'Davis240A':			[240, 180], 
			'Davis240B':			[240, 180], 
			'Davis240C':			[240, 180], 
			'Davis128Mono':		[128, 128], 
			'Davis128Rgb':		[128, 128], 
			'Davis208Mono':		[208, 192], 
			'Davis208Rgbw':		[208, 192], 
			'Davis346AMono':		[346, 260], 
			'Davis346ARgb':		[346, 260], 
			'Davis346BMono':		[346, 260], 
			'Davis346BRgb':		[346, 260], 
			'Davis346CBsi':		[346, 260], 
			'Davis640Mono':		[640, 480], 
			'Davis640Rgb':		[640, 480],
			'DavisHet640Mono':	'Special handling required',
			'DavisHet640Rgbw':	'Special handling required',
			'Das1':				'Special handling required'}
   
    return devices.get(inp, 'DEVICE NOT FOUND')


