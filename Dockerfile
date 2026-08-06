FROM hearmeman/comfyui-minimax-template:v1 AS runtime

# Set working directory
WORKDIR /

# 1. Descarga del modelo principal en un RUN independiente
RUN hf download Phr00t/Qwen-Image-Edit-Rapid-AIO \
    v23/Qwen-Rapid-AIO-NSFW-v23.safetensors \
    --local-dir /ComfyUI/models/diffusion_models/ && \
    rm -rf ~/.cache/huggingface

# 2. Descarga del resto de los modelos (Text Encoder y VAE) en otro RUN
RUN hf download Comfy-Org/Qwen-Image_ComfyUI \
    split_files/text_encoders/qwen_2.5_vl_7b_fp8_scaled.safetensors \
    split_files/vae/qwen_image_vae.safetensors \
    --local-dir /tmp/qwen_downloads/ && \
    mkdir -p /ComfyUI/models/text_encoders /ComfyUI/models/vae && \
    mv /tmp/qwen_downloads/split_files/text_encoders/qwen_2.5_vl_7b_fp8_scaled.safetensors /ComfyUI/models/text_encoders/ && \
    mv /tmp/qwen_downloads/split_files/vae/qwen_image_vae.safetensors /ComfyUI/models/vae/ && \
    rm -rf /tmp/qwen_downloads ~/.cache/huggingface

COPY . .
RUN chmod +x /entrypoint.sh

CMD ["/entrypoint.sh"]