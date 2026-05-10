#!/usr/bin/env python3
"""
Train a binary image classifier (antonine_id vs not_antonine_id)
using MobileNetV2 transfer learning, then export to TFLite.

Usage:
  1. Create two directories:
       train/data/antonine_id/    — photos of real Antonine University IDs
       train/data/not_antonine_id/ — photos of other cards, random objects, etc.
     Aim for 50–200 images per class. Augmentation handles the rest.

  2. Run this script:
       python train/train_id_classifier.py

  3. The script produces:
       assets/models/id_classifier.tflite  — quantized model for mobile
       train/id_classifier_full.h5         — full Keras model (for further tuning)

Requirements:
  pip install tensorflow pillow numpy
"""

import os
import sys

# Ensure we can find the project root
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_ROOT = os.path.dirname(SCRIPT_DIR)
DATA_DIR = os.path.join(SCRIPT_DIR, "data")
OUTPUT_TFLITE = os.path.join(PROJECT_ROOT, "assets", "models", "id_classifier.tflite")
OUTPUT_H5 = os.path.join(SCRIPT_DIR, "id_classifier_full.h5")

IMG_SIZE = 224
BATCH_SIZE = 16
EPOCHS = 20
LEARNING_RATE = 1e-4
FINE_TUNE_AT = 100  # Unfreeze layers from this index onward


def main():
    try:
        import tensorflow as tf
        from tensorflow import keras
        from tensorflow.keras import layers
    except ImportError:
        print("ERROR: TensorFlow not installed. Run: pip install tensorflow")
        sys.exit(1)

    if not os.path.isdir(DATA_DIR):
        print(f"ERROR: Data directory not found at {DATA_DIR}")
        print("Create train/data/antonine_id/ and train/data/not_antonine_id/ with images.")
        sys.exit(1)

    # --- Data loading with augmentation ---
    train_ds = keras.utils.image_dataset_from_directory(
        DATA_DIR,
        validation_split=0.2,
        subset="training",
        seed=42,
        image_size=(IMG_SIZE, IMG_SIZE),
        batch_size=BATCH_SIZE,
        label_mode="binary",
    )

    val_ds = keras.utils.image_dataset_from_directory(
        DATA_DIR,
        validation_split=0.2,
        subset="validation",
        seed=42,
        image_size=(IMG_SIZE, IMG_SIZE),
        batch_size=BATCH_SIZE,
        label_mode="binary",
    )

    class_names = train_ds.class_names
    print(f"Classes: {class_names}")
    print(f"Training batches: {tf.data.experimental.cardinality(train_ds).numpy()}")
    print(f"Validation batches: {tf.data.experimental.cardinality(val_ds).numpy()}")

    # Performance prefetching
    AUTOTUNE = tf.data.AUTOTUNE
    train_ds = train_ds.prefetch(buffer_size=AUTOTUNE)
    val_ds = val_ds.prefetch(buffer_size=AUTOTUNE)

    # Data augmentation
    data_augmentation = keras.Sequential([
        layers.RandomFlip("horizontal"),
        layers.RandomRotation(0.1),
        layers.RandomZoom(0.1),
        layers.RandomContrast(0.1),
    ])

    # --- Model: MobileNetV2 transfer learning ---
    base_model = keras.applications.MobileNetV2(
        input_shape=(IMG_SIZE, IMG_SIZE, 3),
        include_top=False,
        weights="imagenet",
    )
    base_model.trainable = False  # Freeze base initially

    inputs = keras.Input(shape=(IMG_SIZE, IMG_SIZE, 3))
    x = data_augmentation(inputs)
    x = keras.applications.mobilenet_v2.preprocess_input(x)
    x = base_model(x, training=False)
    x = layers.GlobalAveragePooling2D()(x)
    x = layers.Dropout(0.3)(x)
    outputs = layers.Dense(1, activation="sigmoid")(x)

    model = keras.Model(inputs, outputs)
    model.compile(
        optimizer=keras.optimizers.Adam(learning_rate=LEARNING_RATE),
        loss="binary_crossentropy",
        metrics=["accuracy"],
    )

    print("\n--- Phase 1: Train top layers ---")
    model.fit(train_ds, validation_data=val_ds, epochs=EPOCHS // 2)

    # --- Fine-tune: unfreeze deeper layers ---
    base_model.trainable = True
    for layer in base_model.layers[:FINE_TUNE_AT]:
        layer.trainable = False

    model.compile(
        optimizer=keras.optimizers.Adam(learning_rate=LEARNING_RATE / 10),
        loss="binary_crossentropy",
        metrics=["accuracy"],
    )

    print("\n--- Phase 2: Fine-tune ---")
    model.fit(
        train_ds,
        validation_data=val_ds,
        epochs=EPOCHS,
        initial_epoch=EPOCHS // 2,
    )

    # Save full model
    model.save(OUTPUT_H5)
    print(f"\nFull model saved: {OUTPUT_H5}")

    # --- Export to TFLite (quantized) ---
    converter = tf.lite.TFLiteConverter.from_keras_model(model)
    converter.optimizations = [tf.lite.Optimize.DEFAULT]
    tflite_model = converter.convert()

    os.makedirs(os.path.dirname(OUTPUT_TFLITE), exist_ok=True)
    with open(OUTPUT_TFLITE, "wb") as f:
        f.write(tflite_model)

    size_mb = len(tflite_model) / (1024 * 1024)
    print(f"TFLite model saved: {OUTPUT_TFLITE} ({size_mb:.1f} MB)")

    # --- Evaluate ---
    print("\n--- Evaluation ---")
    loss, acc = model.evaluate(val_ds)
    print(f"Validation accuracy: {acc:.2%}")
    print(f"Validation loss: {loss:.4f}")

    print("\nDone! Copy the .tflite file to your Flutter project's assets/models/")
    print("Then set _useStub = false in id_classifier_service.dart")


if __name__ == "__main__":
    main()
