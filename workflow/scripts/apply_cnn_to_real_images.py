# load packages
print("Loading packages...")
import sys, os
import numpy as np
import pandas as pd
from PIL import Image
import tensorflow as tf
from tensorflow import keras
from keras.preprocessing.image import ImageDataGenerator
import scipy

# Check if GPUs are available
#print("Num GPUs Available: ", len(tf.config.list_physical_devices('GPU')))
#tf.debugging.set_log_device_placement(True)

# load in list of file prefixes for images
# split data into training, testing, and validation
print("Reading table of parameters...")
file_prefixes = pd.read_table("real_data_prefixes.txt")
file_prefixes = list(file_prefixes["ID"])

print("Loading images and converting to RGB...")
real_images = np.asarray([np.asarray(Image.open("data/real_images/" + str(x) + ".png").convert('RGB'))/255 for x in file_prefixes])

print("Shapes of training, validation, and testing images:")
print(real_images.shape)

print("Loading position information...")
real_pos = np.asarray([np.asarray(pd.read_table("data/real_positions/" + str(x) + ".txt")) for x in file_prefixes])
print(real_pos.shape)

# load model
print("Loading model...")
model = tf.keras.models.load_model("best_cnn.h5")

# apply model to real images
print("Evaluating model on data...")
real_pred = np.stack([model((real_images, real_pos), training = True) for sample in range(100)])
real_pred_mean = real_pred.mean(axis=0)
real_pred_std = real_pred.std(axis=0)
np.savetxt('real_predictions.txt', np.c_[real_ids, real_pred_mean, real_pred_std], header = "ID tf_mean tf_std", fmt="%s", comments = "")

print("Done! :)")
