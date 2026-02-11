#!/bin/bash

# SPDX-FileCopyrightText: Copyright (c) 2025 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: Apache-2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Exit on error
set -e

echo "Starting environment setup for 3DGRUT in .venv with system packages..."

# Check for required commands
if ! command -v python3 &> /dev/null; then
    echo "Error: python3 could not be found."
    exit 1
fi

if ! command -v git &> /dev/null; then
    echo "Error: git could not be found."
    exit 1
fi

if ! command -v cmake &> /dev/null; then
    echo "Error: cmake could not be found. Please install cmake."
    exit 1
fi

if ! command -v ninja &> /dev/null; then
    echo "Warning: ninja could not be found. It will be installed via pip, but system ninja is recommended."
fi

# Check for GCC
if ! command -v gcc &> /dev/null; then
    echo "Error: gcc could not be found. Please install it."
    exit 1
fi

if ! command -v g++ &> /dev/null; then
    echo "Error: g++ could not be found. Please install it."
    exit 1
fi

# Ideally want gcc-11 for older CUDA, but 12.8 supports newer GCC.
# If gcc-11 specific binary exists, use it, otherwise fallback to system gcc.
if command -v gcc-11 &> /dev/null; then
    export CC=$(which gcc-11)
    export CXX=$(which g++-11)
else
    export CC=$(which gcc)
    export CXX=$(which g++)
fi

echo "Using GCC: $CC"
echo "Using G++: $CXX"

# Check for CUDA Toolkit (nvcc)
if ! command -v nvcc &> /dev/null; then
    echo "Warning: nvcc not found in PATH. Make sure CUDA Toolkit is installed and configured."
else
    echo "Found nvcc: $(which nvcc)"
    nvcc --version
fi

# Create .venv if it doesn't exist
if [ ! -d ".venv" ]; then
    echo "Creating .venv with system site packages..."
    python3 -m venv --system-site-packages .venv
else
    echo ".venv already exists."
fi

# Activate .venv
source .venv/bin/activate

# Upgrade pip
pip install --upgrade pip

# Set Environment Variables for CUDA 12.8 / Blackwell
# Reference from install_env.sh for CUDA 12.8.1
# Added sm_100 (Blackwell), sm_120 based on user request and install_env.sh
export TORCH_CUDA_ARCH_LIST="7.5;8.0;8.6;9.0;10.0;12.0+PTX"
echo "TORCH_CUDA_ARCH_LIST set to: $TORCH_CUDA_ARCH_LIST"

# Install PyTorch for CUDA 12.8
echo "Skipping PyTorch installation as per user request..."
# pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu128
# pip install --force-reinstall "numpy<2"

# Install Kaolin from source (required for CUDA 12.8 currently)
echo "Installing Kaolin from source..."
# Dependencies for building Kaolin
pip install ninja imageio imageio-ffmpeg

if [ -d "thirdparty/kaolin" ]; then
    echo "Removing existing thirdparty/kaolin..."
    rm -rf thirdparty/kaolin
fi

echo "Cloning Kaolin..."
mkdir -p thirdparty
git clone --recursive https://github.com/NVIDIAGameWorks/kaolin.git thirdparty/kaolin
cd thirdparty/kaolin
# Checkout specific commit for reproducibility as per install_env.sh
git checkout c2da967b9e0d8e3ebdbd65d3e8464d7e39005203

# Apply patch for compatibility
echo "Applying patch to Kaolin..."
sed -i 's!AT_DISPATCH_FLOATING_TYPES_AND_HALF(feats_in.type()!AT_DISPATCH_FLOATING_TYPES_AND_HALF(feats_in.scalar_type()!g' kaolin/csrc/render/spc/raytrace_cuda.cu

# Check if kaolin/csrc/render/spc/raytrace_cuda.cu exists to confirm patch worked (optional check)
if [ ! -f "kaolin/csrc/render/spc/raytrace_cuda.cu" ]; then
    echo "Error: Could not find file to patch in Kaolin."
    exit 1
fi

echo "Building and installing Kaolin..."

echo "Installing Kaolin requirements..."
# Install Kaolin build requirements
if [ -f "tools/viz_requirements.txt" ]; then
    pip install -r tools/viz_requirements.txt
fi
if [ -f "tools/requirements.txt" ]; then
    pip install -r tools/requirements.txt
fi
if [ -f "tools/build_requirements.txt" ]; then
    pip install -r tools/build_requirements.txt
fi

# Use IGNORE_TORCH_VER=1 to avoid strict version checks if torch version slightly mismatches
IGNORE_TORCH_VER=1 python setup.py install
cd ../..

# Install other requirements
echo "Installing project requirements..."


# Fallback to root requirements.txt if tools/requirements.txt didn't exist or just in case
if [ -f "requirements.txt" ]; then
    pip install --no-build-isolation -r requirements.txt
fi

# Install the project in editable mode
echo "Installing 3DGRUT in editable mode..."
pip install --no-build-isolation -e .

echo "Setup completed successfully!"
echo "To activate the environment, run: source .venv/bin/activate"
