#!/bin/bash

# Sin "set -e" global: manejamos los errores explicitamente
echo "Checking CUDA availability..."

python3 - <<'PY'
import sys
try:
    import torch
    if torch.cuda.is_available():
        sys.exit(0)
    print("CUDA_NOT_AVAILABLE"); sys.exit(1)
except Exception as e:
    print(f"CUDA_ERROR: {e}"); sys.exit(2)
PY
rc=$?
case $rc in
    0)
        echo "✅ CUDA is available and working (Python check)"
        export CUDA_VISIBLE_DEVICES=0
        export FORCE_CUDA=1
        ;;
    *)
        echo "❌ CUDA check failed (code $rc). Exiting..."
        exit 1
        ;;
esac

if command -v nvidia-smi &> /dev/null && nvidia-smi &> /dev/null; then
    echo "✅ NVIDIA driver working (nvidia-smi check)"
else
    echo "❌ NVIDIA driver not found or not working. Exiting..."
    exit 1
fi

echo "Using CUDA device: $CUDA_VISIBLE_DEVICES"

# Arranca ComfyUI en background y guarda su PID
echo "Starting ComfyUI in the background..."
python /ComfyUI/main.py --listen --use-sage-attention &
COMFY_PID=$!

echo "Waiting for ComfyUI to be ready..."
max_wait=300   # segundos
elapsed=0
ready=0
while [ $elapsed -lt $max_wait ]; do
    # Si ComfyUI murio, no tiene sentido seguir esperando
    if ! kill -0 "$COMFY_PID" 2>/dev/null; then
        echo "❌ ComfyUI process died during startup (ver traceback arriba). Exiting..."
        exit 1
    fi
    if curl -s http://127.0.0.1:8188/ > /dev/null 2>&1; then
        echo "ComfyUI is ready!"
        ready=1
        break
    fi
    echo "Waiting for ComfyUI... ($elapsed/$max_wait)"
    sleep 2
    elapsed=$((elapsed + 2))
done

if [ $ready -ne 1 ]; then
    echo "❌ ComfyUI failed to start within $max_wait seconds"
    exit 1
fi

echo "Starting the handler..."
cd /
exec python handler.py
