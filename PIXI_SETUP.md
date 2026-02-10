# Pixi Setup Guide for 3DGRUT

This guide explains how to set up and use the 3DGRUT environment using [Pixi](https://pixi.sh), a modern package manager that replaces conda/mamba workflows.

## Prerequisites

1. **Install Pixi** (if not already installed):
   ```bash
   curl -fsSL https://pixi.sh/install.sh | bash
   ```

2. **CUDA 11.8+ Compatible System**
   - For best performance with 3DGRT, use an NVIDIA GPU with Ray Tracing (RT) cores
   - For Blackwell GPUs (RTX 5090, compute capability 10.0+), see the CUDA 12.8 section below

3. **GCC Version** (for Ubuntu 24.04 or systems with gcc > 11):
   ```bash
   sudo apt-get install gcc-11 g++-11
   ```

## Quick Start (CUDA 11.8)

1. **Clone the repository** (if not already done):
   ```bash
   git clone --recursive https://github.com/nv-tlabs/3dgrut.git
   cd 3dgrut
   ```

2. **Install dependencies**:
   ```bash
   pixi install
   ```

3. **Complete the setup** (install kaolin, submodules, and package):
   ```bash
   pixi run install-all
   ```

4. **Activate the environment**:
   ```bash
   pixi shell
   ```

## Blackwell GPU Support (CUDA 12.8)

For RTX 5090 or other Blackwell GPUs with compute capability 10.0+:

1. **Install with CUDA 12.8 feature**:
   ```bash
   pixi install --feature cuda12
   ```

2. **Note**: CUDA 12.8 requires building kaolin from source. This is handled automatically but takes longer.

## Available Tasks

Pixi provides convenient task shortcuts:

### Installation Tasks
- `pixi run init-submodules` - Initialize git submodules
- `pixi run install-kaolin` - Install kaolin library
- `pixi run install-package` - Install 3dgrut package in editable mode
- `pixi run install-all` - Run all installation steps

### Training and Rendering
- `pixi run train` - Run training script
- `pixi run render` - Run rendering script
- `pixi run playground` - Launch interactive playground

### Benchmarks
- `pixi run benchmark-nerf` - Run NeRF synthetic benchmark
- `pixi run benchmark-mipnerf360` - Run MipNeRF360 benchmark
- `pixi run benchmark-scannetpp` - Run ScanNet++ benchmark

## Usage Examples

### Train a scene with 3DGRT
```bash
pixi run train --config-name apps/nerf_synthetic_3dgrt.yaml path=data/nerf_synthetic/lego out_dir=runs experiment_name=lego_3dgrt
```

### Train a scene with 3DGUT
```bash
pixi run train --config-name apps/nerf_synthetic_3dgut.yaml path=data/nerf_synthetic/lego out_dir=runs experiment_name=lego_3dgut
```

### Render from checkpoint
```bash
pixi run render --checkpoint runs/lego/ckpt_last.pt --out-dir outputs/eval
```

### Interactive visualization
```bash
pixi run train --config-name apps/nerf_synthetic_3dgut.yaml path=data/nerf_synthetic/lego with_gui=True
```

## Environment Variables

The following environment variables are automatically set:

- **TORCH_CUDA_ARCH_LIST**: 
  - CUDA 11.8: `7.0;7.5;8.0;8.6;9.0` (supports up to compute capability 9.0)
  - CUDA 12.8: `7.5;8.0;8.6;9.0;10.0;12.0` (supports Blackwell GPUs)

## Differences from Conda Setup

| Aspect | Conda (`install_env.sh`) | Pixi (`pixi.toml`) |
|--------|-------------------------|-------------------|
| Environment file | Manual script | Declarative TOML |
| Dependency resolution | conda/pip mixed | Unified with pixi |
| Reproducibility | Environment export | Lock file (`pixi.lock`) |
| Activation | `conda activate 3dgrut` | `pixi shell` or `pixi run` |
| Task running | Manual commands | `pixi run <task>` |

## Troubleshooting

### GCC Version Issues
If you encounter gcc version errors:
```bash
# Install gcc-11
sudo apt-get install gcc-11 g++-11

# Set environment variables (pixi handles this automatically)
export CC=gcc-11
export CXX=g++-11
```

### CUDA Toolkit Not Found
Ensure you're using the correct feature:
- Default: CUDA 11.8
- Blackwell GPUs: Use `--feature cuda12`

### Kaolin Installation Fails
Try installing kaolin manually:
```bash
pixi shell
pip install --find-links https://nvidia-kaolin.s3.us-east-2.amazonaws.com/torch-2.1.2_cu118.html kaolin==0.17.0
```

## Additional Resources

- [Pixi Documentation](https://pixi.sh/latest/)
- [3DGRT Project Page](https://research.nvidia.com/labs/toronto-ai/3DGRT)
- [3DGUT Project Page](https://research.nvidia.com/labs/toronto-ai/3DGUT)
- [Original README](README.md)
