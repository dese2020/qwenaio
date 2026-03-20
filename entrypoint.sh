#!/bin/bash
set -e

echo "========== RUNPOD WORKER INIT =========="

########################################
# 1. GPU VALIDATION (FAIL FAST)
########################################
echo "[CHECK] GPU info..."

GPU_NAME=$(nvidia-smi --query-gpu=name --format=csv,noheader | head -n1 || echo "unknown")
VRAM=$(nvidia-smi --query-gpu=memory.total --format=csv,noheader,nounits | head -n1 || echo "0")

echo "[INFO] GPU: $GPU_NAME"
echo "[INFO] VRAM: ${VRAM}MB"

# Ajusta según tu modelo
MIN_VRAM=16000

if [ "$VRAM" -lt "$MIN_VRAM" ]; then
    echo "[FAIL] GPU incompatible (VRAM < ${MIN_VRAM}MB)"
    exit 2
fi

########################################
# 2. START COMFYUI
########################################
echo "[START] Launching ComfyUI..."

python /ComfyUI/main.py --listen --use-sage-attention &
COMFY_PID=$!

echo "[INFO] ComfyUI PID: $COMFY_PID"

########################################
# 3. EARLY CRASH DETECTION
########################################
sleep 5

if ! kill -0 $COMFY_PID 2>/dev/null; then
    echo "[FAIL] ComfyUI crashed immediately"
    exit 3
fi

########################################
# 4. SMART HEALTHCHECK
########################################
echo "[WAIT] Waiting for ComfyUI API..."

max_wait=60
wait_count=0

while [ $wait_count -lt $max_wait ]; do

    # proceso muerto → salir
    if ! kill -0 $COMFY_PID 2>/dev/null; then
        echo "[FAIL] ComfyUI died during startup"
        exit 4
    fi

    # API OK
    if curl -s http://127.0.0.1:8188/ > /dev/null 2>&1; then
        echo "[OK] ComfyUI is ready"
        break
    fi

    echo "[WAIT] ${wait_count}s / ${max_wait}s"
    sleep 2
    wait_count=$((wait_count + 2))
done

if [ $wait_count -ge $max_wait ]; then
    echo "[FAIL] Timeout waiting for ComfyUI"
    kill -9 $COMFY_PID
    exit 5
fi

########################################
# 5. START HANDLER
########################################
echo "[START] Handler..."

exec python handler.py