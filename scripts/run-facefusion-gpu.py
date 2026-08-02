"""Launch FaceFusion with the CUDA runtime DLLs bundled in its virtualenv."""

from __future__ import annotations

import ctypes
import os
import runpy
import sys
from pathlib import Path


def preload_cuda_runtime() -> None:
    site_packages = Path(sys.prefix) / "Lib" / "site-packages" / "nvidia"
    directories = ["cuda_runtime", "cublas", "cudnn", "cufft", "nvjitlink"]

    # Keep the handles alive for the lifetime of the FaceFusion process.
    dll_directory_handles = [
        os.add_dll_directory(str(site_packages / directory / "bin"))
        for directory in directories
    ]
    globals()["_dll_directory_handles"] = dll_directory_handles

    dlls = [
        ("cuda_runtime", "cudart64_12.dll"),
        ("nvjitlink", "nvJitLink_120_0.dll"),
        ("cublas", "cublasLt64_12.dll"),
        ("cublas", "cublas64_12.dll"),
        ("cufft", "cufft64_11.dll"),
        ("cudnn", "cudnn64_9.dll"),
        ("cudnn", "cudnn_ops64_9.dll"),
        ("cudnn", "cudnn_cnn64_9.dll"),
        ("cudnn", "cudnn_adv64_9.dll"),
        ("cudnn", "cudnn_graph64_9.dll"),
        ("cudnn", "cudnn_heuristic64_9.dll"),
        ("cudnn", "cudnn_engines_runtime_compiled64_9.dll"),
        ("cudnn", "cudnn_engines_precompiled64_9.dll"),
    ]
    for directory, filename in dlls:
        ctypes.WinDLL(str(site_packages / directory / "bin" / filename))


def main() -> None:
    preload_cuda_runtime()
    root = Path(__file__).resolve().parents[1]
    facefusion_entry = root / "tools" / "facefusion" / "facefusion.py"
    facefusion_bin = facefusion_entry.parent / "bin"
    os.environ["PATH"] = str(facefusion_bin) + os.pathsep + os.environ.get("PATH", "")
    sys.path.insert(0, str(facefusion_entry.parent))
    sys.argv = [str(facefusion_entry), *sys.argv[1:]]
    runpy.run_path(str(facefusion_entry), run_name="__main__")


if __name__ == "__main__":
    main()
