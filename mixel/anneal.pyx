from __future__ import division,print_function
import numpy as np
cimport numpy as np 
import colorsys
from random import randint,random
from math import exp
from animate import print_replace

ctypedef np.uint8_t DTYPE_t

cpdef dist(pixel1,pixel2,r_weight,g_weight,b_weight,luma_weight):
	cdef float r_diff = pixel1[0]-pixel2[0]*r_weight
	cdef float g_diff = pixel1[1]-pixel2[1]*g_weight
	cdef float b_diff = pixel1[2]-pixel2[2]*b_weight
	cdef float total = r_diff*r_diff+g_diff*g_diff+b_diff*b_diff
	total+=luma_weight*(r_diff+g_diff+b_diff)
	return total
	
cpdef swap(array,x1,x2,y1,y2):
	#we can't use typical a,b=b,a syntax as it doesn't always work on numpy
	temp = np.copy(array[y1,x1])
	array[y1,x1] = array[y2,x2]
	array[y2,x2] = temp
	
def anneal(np.ndarray[DTYPE_t,ndim=3] input_img,np.ndarray[DTYPE_t,ndim=3] target_img, \
			 verbose=True,rgb_weights=(0.114,0.587,0.299),init_rand=0,rand_decay=0, \
			 n_steps=None,stop_limit=None,luma_weight=10):
	if init_rand<0 or init_rand>1:
		raise ValueError('init_rand must be in range [0,1]')
	if rand_decay<0:
		raise ValueError('rand_decay must be non-negative')
	if any([x<0 for x in rgb_weights]):
		raise ValueError('All rgb_weights must be non-negative')
	if luma_weight<0:
		raise ValueError('luma_weight must be non-negative')
	if n_steps is None and stop_limit is None:
		n_steps = 2500000
		step_flag = True
	elif n_steps is not None:
		step_flag = True
	else:
		step_flag = False
	
	if verbose:
		print('Performing simulated annealing...')
	output_img = np.copy(input_img)
	
	cdef float r_weight,g_weight,b_weight
	r_weight,g_weight,b_weight = rgb_weights
	
	cdef int x1,x2,y1,y2,height,width
	cdef float current_dist,candidate_dist,flip_chance
		
	cdef int step_count = 0
	cdef int no_change_count = 0
	cdef int max_no_change_count = 0
	cdef int n_swapped = 0
	height,width,_ = output_img.shape
	while step_count<=n_steps if step_flag else no_change_count>stop_limit:
		if verbose and step_count%10000==0 and step_count!=0:
			max_no_change_count = max(max_no_change_count,no_change_count)
			if step_flag:
				print_replace('Step %d of %d; swapped %d pairs of pixels so far; ' % \
								(step_count,n_steps,n_swapped)+'longest stable run is %d' % \
								max_no_change_count)
			else:
				print_replace('Step %d; swapped %d pairs of pixels so far; ' % \
								(step_count,n_steps,n_swapped)+'longest stable run is %d' % \
								max_no_change_count)
	
		x1 = randint(0,width-1)
		x2 = randint(0,width-1)
		y1 = randint(0,height-1)
		y2 = randint(0,height-1)
		
		current_dist = dist(output_img[y1,x1],target_img[y1,x1],r_weight,g_weight,b_weight,luma_weight) \
						 +dist(output_img[y2,x2],target_img[y2,x2],r_weight,g_weight,b_weight,luma_weight)
		candidate_dist = dist(output_img[y1,x1],target_img[y2,x2],r_weight,g_weight,b_weight,luma_weight) \
						 +dist(output_img[y2,x2],target_img[y1,x1],r_weight,g_weight,b_weight,luma_weight)
			
		flip_chance = init_rand*exp(-step_count*rand_decay)
		if candidate_dist<current_dist:
			max_no_change_count = max(max_no_change_count,no_change_count)
			no_change_count = 0
			n_swapped+=1
			swap(output_img,x1,x2,y1,y2)
		else:
			no_change_count+=1
			if random()<flip_chance:
				n_swapped+=1
				swap(output_img,x1,x2,y1,y2)
			
		step_count+=1
	
	if verbose: 
		print()
	return output_img