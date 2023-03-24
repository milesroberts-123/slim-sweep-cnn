# load packages
print("Loading packages...")
import sys, os
import numpy as np
import pandas as pd
from PIL import Image
import keras

print("Getting paths to input images...")
image_paths = os.listdir("data/images/")

print("List of input images:")
print(image_paths)

# load the image
# image = Image.open('Picture1.jpg')

# convert image to numpy array
# data = np.asarray(image)
#print(type(data))

# summarize shape
# print(data.shape)
