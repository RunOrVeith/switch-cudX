# switch-cudX

```bash
This script allows to switch the active CUDA version between all installed versions.
You may also use it to install cudnn for the first time.
Syntax: ./switch_cuda [options] [cuda-version [options]].

Parameters:
	Positional:
		cuda-version	Version number of wanted CUDA installation,
				e.g. ./switch_cuda 7.0 for CUDA 7.0.
	Optional:
		-c		Directory that contains CuDNN. If left empty,
				CuDNN will not be installed. However, old
				existing versions will not be touched.
				Example: ./switch_cuda 7.0 -c ~/Downloads/cudnn5.1/cuda/
		
		-i 		List your current CUDA/CuDNN setup

		-s		Location for your active CUDA version symlink.
				Only required if different to /usr/local/cuda,
				which probably does not apply to you.
		
		-h		Display this help message.
```

This works on Ubuntu 16.04 and 18.04. No other systems have been tested.
