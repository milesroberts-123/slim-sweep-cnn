# RISE algorithm for interpreting CNNs
# In other words, randomly mask parts of image, have your model make predictions, see which pixels affect the predictions most when masked
# Code is from: https://spacetelescope.github.io/hellouniverse/notebooks/hello-universe/Interpreting_CNNs/Interpreting_CNNs.html#rise-algorithm
# Relevant citation: https://doi.org/10.48550/arXiv.1806.07421
import sys, os
import numpy as np
import pandas as pd
from PIL import Image
import tensorflow as tf
from tensorflow import keras
from matplotlib import pyplot as plt

#
path = "data/images/"
slim_params = "stratified_sample_18.tsv"
finalModelName = "best_cnn.h5"

# split data into training, testing, and validation
print("Reading table of parameters...")
slim_params = pd.read_table(slim_params)

print("Splitting table into training, validation, and testing...")
train_params = slim_params[slim_params["split"] == "train"].copy().reset_index()
val_params = slim_params[slim_params["split"] == "val"].copy().reset_index()
test_params = slim_params[slim_params["split"] == "test"].copy().reset_index()

print(train_params)
print(val_params)
print(test_params)

train_ids = list(train_params["ID"])
val_ids = list(val_params["ID"])
test_ids = list(test_params["ID"])

print("Loading images and converting to RGB...")
train_images = np.asarray([np.asarray(Image.open(path + "slim_" + str(x) + ".png").convert('RGB'))/255 for x in train_ids if os.path.exists(path + "slim_" + str(x) + ".png")])
val_images = np.asarray([np.asarray(Image.open(path + "slim_" + str(x) + ".png").convert('RGB'))/255 for x in val_ids if os.path.exists(path + "slim_" + str(x) + ".png")])
test_images = np.asarray([np.asarray(Image.open(path + "slim_" + str(x) + ".png").convert('RGB'))/255 for x in test_ids if os.path.exists(path + "slim_" + str(x) + ".png")])

print("Shapes of training, validation, and testing images:")
print(train_images.shape)
print(val_images.shape)
print(test_images.shape)

# load tables to get position information from slim
print("Loading position information...")
train_pos = np.asarray([np.asarray(pd.read_table("data/positions/slim_" + str(x) + ".pos")) for x in train_ids if os.path.exists("data/positions/slim_" + str(x) + ".pos")])
val_pos = np.asarray([np.asarray(pd.read_table("data/positions/slim_" + str(x) + ".pos")) for x in val_ids if os.path.exists("data/positions/slim_" + str(x) + ".pos")])
test_pos = np.asarray([np.asarray(pd.read_table("data/positions/slim_" + str(x) + ".pos")) for x in test_ids if os.path.exists("data/positions/slim_" + str(x) + ".pos")])

# load model
print("Loading model...")
model = tf.keras.models.load_model("best_cnn.h5")

# Choose the image to analyze
img_idx = 46
input_shape = (128, 128, 3)

# We can change the index to any number in range of the test set
image = test_images[img_idx]
position = test_pos[img_idx]

print("Create masks...")
N = 10000  # Number of masks
#s = 4     # Size of the grid
p1 = 0.05  # Probability of the cell being set to 1
#cell_size = np.ceil(np.array(input_shape[:2]) / s).astype(int)
#up_size = (s * cell_size).astype(int)
#grid = np.random.rand(N, s, s) < p1
#masks = np.empty((N, *input_shape[:2]))

#for i in range(N):
    # Randomly place the grid on the image
#    x = np.random.randint(0, input_shape[0]-s)
#    y = np.random.randint(0, input_shape[1]-s)
#    mask = np.pad(grid[i], ((x, input_shape[0]-x-s), (y, input_shape[0]-y-s)), 'constant', constant_values=(0, 0))
#    mask = mask[:input_shape[0], :input_shape[1]]
#    masks[i] = mask

#masks = masks.reshape(-1, *input_shape[:2], 1)


masked_rows = np.random.rand(N, input_shape[0]) < p1
masked_columns = np.random.rand(N, input_shape[1]) < p1

masks = np.ones((N, *input_shape[:2]))
for i in range(N):
    mask = masks[i]
    mask[masked_rows[i]] = np.zeros(input_shape[0])
    mask[:,masked_columns[i]] = 0
    masks[i] = mask

masks = masks.reshape(-1, *input_shape[:2], 1)

print("Get predictions on masked images...")
#N = len(masks)
print(np.shape(image*masks))
print(np.shape(np.repeat(position[np.newaxis,...], N, axis = 0)))
pred_masks = model.predict([image*masks, np.repeat(position[np.newaxis,...], N, axis = 0)])
pred_masks = np.expand_dims(pred_masks, axis=-1)
pred_masks = np.expand_dims(pred_masks, axis=-1) # Reshape pred_masks for broadcasting
heatmap = (pred_masks * masks).sum(axis=0)
heatmap = heatmap / N / p1

# Plot the results next to the original image
print("Plot heatmap...")

fig, axes = plt.subplots(1, 2, figsize=(14, 5))
axes[0].imshow(image)
axes[0].set_title("original image")
i = axes[1].imshow(heatmap, cmap="turbo")
fig.colorbar(i)
axes[1].set_title("heatmap")

plt.savefig('heatmap.png')
