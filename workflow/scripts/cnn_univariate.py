# load packages
print("Loading packages...")
import sys, os
import numpy as np
import pandas as pd
from PIL import Image
import tensorflow as tf
from tensorflow import keras
#import matplotlib.pyplot as plt
#from keras.optimizers import SGD
from keras.preprocessing.image import ImageDataGenerator
import scipy
import keras_tuner

# Check if GPUs are available
#print("Num GPUs Available: ", len(tf.config.list_physical_devices('GPU')))
#tf.debugging.set_log_device_placement(True)

# define parameters
path = "data/images/"
batch_size = 32
epochs = 200
patience = 20
#slim_params = "../config/parameters.tsv"
slim_params = "stratified_sample_20.tsv"
weightFolderName = "data/weights"
finalModelName = "best_cnn.h5"
outcome_variable = "tf"

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

#print("Splitting response variable into training, validation, and testing...")
#train_y = train_params["sweepS"]
#val_y = val_params["sweepS"]
#test_y = test_params["sweepS"]

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

# reformat IDs, and log transform dependent variable
train_params['ID'] = train_params['ID'].astype(str)
val_params['ID'] = val_params['ID'].astype(str)

train_params['ID'] = train_params["ID"].replace(to_replace = r"$", value = ".png", regex = True).replace(to_replace = r"^", value = "slim_", regex = True)
val_params['ID'] = val_params["ID"].replace(to_replace = r"$", value = ".png", regex = True).replace(to_replace = r"^", value = "slim_", regex = True)

train_params['tf'] = train_params['tf'].apply(np.log10)
val_params['tf'] = val_params['tf'].apply(np.log10)
test_params['tf'] = test_params['tf'].apply(np.log10)

train_params['ta'] = train_params['ta'].apply(np.log10)
val_params['ta'] = val_params['ta'].apply(np.log10)
test_params['ta'] = test_params['ta'].apply(np.log10)

# load fixation times
#print("Loading fixation times...")
#train_y = np.asarray([float(open("data/fix_times/fix_time_" + str(x) + ".txt").read()) for x in train_ids if os.path.exists("data/fix_times/fix_time_" + str(x) + ".txt")])
#val_y = np.asarray([float(open("data/fix_times/fix_time_" + str(x) + ".txt").read()) for x in val_ids if os.path.exists("data/fix_times/fix_time_" + str(x) + ".txt")])
#test_y = np.asarray([float(open("data/fix_times/fix_time_" + str(x) + ".txt").read()) for x in test_ids if os.path.exists("data/fix_times/fix_time_" + str(x) + ".txt")])

# transform fixation times
#train_y = np.log10(train_y)
#val_y = np.log10(val_y)
#test_y = np.log10(test_y)
#print(train_y)
#print(val_y)
#print(test_y)

# subset to only simulations which you have images for
#print("Subsetting response variable to only finished simulations...")
#train_y = np.asarray([train_y[(x-1)] for x in train_ids if os.path.exists(path + "slim_" + str(x) + ".png")])
#val_y = np.asarray([val_y[(x-1)] for x in val_ids if os.path.exists(path + "slim_" + str(x) + ".png")])
#test_y = np.asarray([test_y[(x-1)] for x in test_ids if os.path.exists(path + "slim_" + str(x) + ".png")])
#train_y = np.asarray([slim_params.iloc[(x-1), 5] for x in train_ids if os.path.exists(path + "slim_" + str(x) + ".png")])
#val_y = np.asarray([slim_params.iloc[(x-1), 5] for x in val_ids if os.path.exists(path + "slim_" + str(x) + ".png")])
#test_y = np.asarray([slim_params.iloc[(x-1), 5] for x in test_ids if os.path.exists(path + "slim_" + str(x) + ".png")])

#print(train_y.shape)
#print(val_y.shape)
#print(test_y.shape)

#print(train_y)
#print(val_y)
#print(test_y)

#print("Converting response to binary outcome...")
#train_y[np.where(train_y == 0.5)] = 1
#val_y[np.where(val_y == 0.5)] = 1
#test_y[np.where(test_y == 0.5)] = 1
#train_y = (train_y == 0.5)
#val_y = (val_y == 0.5)
#test_y = (test_y == 0.5)

# load tables to get position information from slim
print("Loading position information...")
train_pos = np.asarray([np.asarray(pd.read_table("data/positions/slim_" + str(x) + ".pos")) for x in train_ids if os.path.exists("data/positions/slim_" + str(x) + ".pos")])
val_pos = np.asarray([np.asarray(pd.read_table("data/positions/slim_" + str(x) + ".pos")) for x in val_ids if os.path.exists("data/positions/slim_" + str(x) + ".pos")])
test_pos = np.asarray([np.asarray(pd.read_table("data/positions/slim_" + str(x) + ".pos")) for x in test_ids if os.path.exists("data/positions/slim_" + str(x) + ".pos")])

print(train_pos.shape)
print(val_pos.shape)
print(test_pos.shape)

# Create model with functional API
# https://keras.io/guides/keras_tuner/getting_started/
def build_model(hp):
  print("Creating model...")
  input_A = keras.layers.Input(shape = [128,128,3], name = "images")
  input_B = keras.layers.Input(shape = [128], name = "positions")
  conv1 = keras.layers.Conv2D(filters = hp.Int("conv1-filters", min_value=16, max_value=128, step=16), kernel_size = 7, strides = 2, padding = "same", activation = "relu", input_shape = [128,128,3])(input_A)
  pool1 = keras.layers.MaxPooling2D(2)(conv1)
  pool1 = keras.layers.Dropout(hp.Float(name = "pool1-dropout", min_value=0, max_value=0.99))(pool1)
  conv2 = keras.layers.Conv2D(filters = hp.Int("conv2-filters", min_value=16, max_value=128, step=16), kernel_size = 3, strides = 1, padding = "same", activation = "relu")(pool1)
  pool2 = keras.layers.MaxPooling2D(2)(conv2)
  pool2 = keras.layers.Dropout(hp.Float(name = "pool2-dropout", min_value=0, max_value=0.99))(pool2)
  conv3 = keras.layers.Conv2D(filters = hp.Int("conv3-filters", min_value=16, max_value=128, step=16), kernel_size = 3, strides = 1, padding = "same", activation = "relu")(pool2)
  pool3 = keras.layers.MaxPooling2D(2)(conv3)
  pool3 = keras.layers.Dropout(hp.Float(name = "pool3-dropout", min_value=0, max_value=0.99))(pool3)
  flat = keras.layers.Flatten()(pool3)
  dense_A = keras.layers.Dense(units=hp.Int("denseA-units", min_value=32, max_value=512, step=32), activation = "relu")(flat)
  dense_A = keras.layers.Dropout(hp.Float(name = "denseA-dropout", min_value=0, max_value=0.99))(dense_A)
  dense_B = keras.layers.Dense(units=hp.Int("denseB-units", min_value=32, max_value=512, step=32), activation = "relu")(input_B)
  dense_B = keras.layers.Dropout(hp.Float(name = "denseB-dropout", min_value=0, max_value=0.99))(dense_B)
  concat = keras.layers.concatenate(inputs = [dense_A, dense_B])
  full = keras.layers.Dense(units=hp.Int("full-units", min_value=32, max_value=512, step=32), activation = "relu")(concat)
  full = keras.layers.Dropout(hp.Float(name = "full-dropout", min_value=0, max_value=0.99))(full)
  output = keras.layers.Dense(1, name = "output")(full)
  model = keras.Model(inputs = [input_A, input_B], outputs = [output])

  # compile model
  print("Compiling model...")
  model.compile(optimizer='adam', loss="mse", metrics = [tf.keras.metrics.MeanSquaredError()])

  return model


# build hyperparameter tuner
tuner = keras_tuner.BayesianOptimization(
    hypermodel=build_model,
    objective="val_mean_squared_error",
    max_trials=60,
    overwrite=True,
    directory="tuning_dir",
    project_name="slimcnn",
)

# print summary of search space
tuner.search_space_summary()

# Seach hyperparameter space
print("Starting search...")
tuner.search((train_images, train_pos), train_params[outcome_variable], epochs=2, validation_data=((val_images, val_pos), val_params[outcome_variable]))

# Get the top 2 models.
print("Extract best model...")
models = tuner.get_best_models(num_models=2)
best_model = models[0]
best_model.summary()
model = best_model

# add callbacks: early stopping and saving at checkpoints
earlystop = keras.callbacks.EarlyStopping(monitor='val_loss', min_delta=0.0, patience=patience, verbose=0, mode='auto')
checkpoint = keras.callbacks.ModelCheckpoint(weightFolderName, monitor='val_loss', verbose=1, save_best_only=True, mode='min')
callbacks = [earlystop, checkpoint]

# add image generator
print("Creating image generators...")

def createGenerator(dff, np_arrays, batch_size, my_directory, xcolumn, ycolumn):
    # create image generator
    mydatagen = ImageDataGenerator(rescale = 1./255, horizontal_flip = True, vertical_flip = True)

    # Shuffles the dataframe, and so the batches as well
    dff = dff.sample(frac=1)
    np_arrays = np_arrays[dff.index]

    # Shuffle=False is EXTREMELY important to keep order of image and coord
    flow = mydatagen.flow_from_dataframe(
                                        dataframe=dff,
                                        directory=my_directory,
                                        x_col=xcolumn,
                                        y_col=ycolumn,
                                        batch_size=batch_size,
                                        shuffle=False,
                                        class_mode="other",
                                        target_size=(128,128)
                                      )
    idx = 0
    n = len(dff) - batch_size
    batch = 0
    while True :
        # Get next batch of images
        X1 = flow.next()
        # idx to reach
        end = idx + X1[0].shape[0]
        # get next batch of lines from df
        X2 = np_arrays[idx:end]
        X2 = np.squeeze(X2)
        # Updates the idx for the next batch
        print(", batch: ", batch, ", batch size: ", X1[0].shape[0], ", batch start: ", idx, ", batch end: ", end)
        idx = end
        batch+=1
        # Checks if we are at the end of the dataframe
        if idx==len(dff):
            # print("END OF THE DATAFRAME\n")
            idx = 0

        #print(X1[0].shape)
        #print(X1[1].shape)
        #print(X2.shape)

        yield [X1[0], X2], X1[1]  #Yield both images, metadata and their mutual label

print("Test custom generator...")

train_generator = createGenerator(train_params, train_pos, batch_size, "data/images/", "ID", outcome_variable)
val_generator = createGenerator(val_params, val_pos, batch_size, "data/images/", "ID", outcome_variable)

#train_generator = mydatagen.flow_from_dataframe(dataframe=train_params, directory="data/images/", 
#                                              x_col="ID", y_col="tf", has_ext=True, 
#                                              class_mode="other", target_size=(128, 128), 
#                                              batch_size=batch_size)

#val_generator = mydatagen.flow_from_dataframe(dataframe=val_params, directory="data/images/",
#                                              x_col="ID", y_col="tf", has_ext=True,
#                                              class_mode="other", target_size=(128, 128),
#                                              batch_size=batch_size)

# fit model
print("Fitting model...")
#history = model.fit((train_images, train_pos), train_y, batch_size=batch_size, epochs=epochs, verbose=1, validation_data=((val_images, val_pos), val_y), callbacks=callbacks)
history = model.fit(train_generator, batch_size=batch_size, epochs=epochs, verbose=1, validation_data=val_generator, callbacks=callbacks, steps_per_epoch = int(np.ceil(train_pos.shape[0] / batch_size)), validation_steps = int(np.ceil(val_pos.shape[0] / batch_size)))

# evaluate total error in model
print("Evaluating model on testing data...")
test_pred = np.stack([model((test_images, test_pos), training = True) for sample in range(100)])
test_pred_mean = test_pred.mean(axis=0)
test_pred_std = test_pred.std(axis=0)
np.savetxt('test_predicted_vs_actual.txt', np.c_[test_ids, test_params[outcome_variable], test_pred_mean, test_pred_std], header = "ID true_tf pred_tf_mean pred_tf_std")

print("Evaluating model on validation data...")
val_pred = np.stack([model((val_images, val_pos), training = True) for sample in range(100)])
val_pred_mean = val_pred.mean(axis=0)
val_pred_std = val_pred.std(axis=0)
np.savetxt('val_predicted_vs_actual.txt', np.c_[val_ids, val_params[outcome_variable], val_pred_mean, val_pred_std], header = "ID true_tf pred_tf_mean pred_tf_std")

print("Evaluating model on training data...")
train_pred = np.stack([model((train_images, train_pos), training = True) for sample in range(100)])
train_pred_mean = train_pred.mean(axis=0)
train_pred_std = train_pred.std(axis=0)
np.savetxt('train_predicted_vs_actual.txt', np.c_[train_ids, train_params[outcome_variable], train_pred_mean, train_pred_std], header = "ID true_tf pred_tf_mean pred_tf_std")

# test model
#print("Testing model...")
#val_pred = model.predict(val_images)
#test_pred = model.predict(test_images)

#print(val_y)
#print(val_pred)

#print(test_y)
#print(test_pred)
#print(keras.metrics.confusion_matrix(test_y, test_pred))

# plot predictions against real values
#plt.scatter(test_y, final_pred)
#plt.xlabel("Real selection coefficient")
#plt.ylabel("Predicted selection coefficient")
#plt.plot([0,0.05], [0,0.05], color='k', linestyle='-', linewidth=2)
#plt.savefig('test_real_vs_predictions.png')
#plt.close()

# plot training data predictions against real values
#train_pred = model.predict(train_images)
#plt.scatter(train_y, train_pred)
#plt.xlabel("Real selection coefficient")
#plt.ylabel("Predicted selection coefficient")
#plt.plot([0,0.05], [0,0.05], color='k', linestyle='-', linewidth=2)
#plt.savefig('train_real_vs_predictions.png')
#plt.close()

# save model
print("Saving final model...")
model.save(finalModelName)

# save comparison of predictions vs actual
print("Saving comparison of predicted vs actual values...")

print("Done! :)")
