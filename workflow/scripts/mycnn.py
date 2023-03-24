# load packages
print("Loading packages...")
import sys, os
import numpy as np
import pandas as pd
from PIL import Image
import keras
import matplotlib.pyplot as plt

path = "data/images/"

print("Getting paths to input images...")
image_paths = os.listdir(path)
image_paths = [path + x for x in image_paths]

print("List of input images:")
print(image_paths)

# load the images into a numpy array
# 4-dimmensions:
# 1st: number of images
# 2nd
print("Loading the images to a numpy array")
images = np.asarray([np.asarray(Image.open(x))/255 for x in image_paths])

print(images.shape)
print(images[0].shape)

# plot image to ensure code works correctly
plt.imshow(images[0])
plt.savefig('test.jpg')

# convert image to numpy array
# data = np.asarray(image)
#print(type(data))

# summarize shape
# print(data.shape)
