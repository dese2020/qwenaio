# Imagen base con ComfyUI ya instalado en /ComfyUI
FROM hearmeman/comfyui-minimax-template:v9 AS runtime

# wget (para descargar imagenes por URL) y curl (para el healthcheck del entrypoint)
RUN apt-get update && apt-get install -y wget curl && rm -rf /var/lib/apt/lists/*

# IMPORTANTE: NO usar "-U" aqui. huggingface_hub 2.x rompe transformers
# (exige >=1.5.0,<2.0). Se fija el rango compatible.
RUN pip install "huggingface_hub[hf_transfer]>=1.5.0,<2.0"
RUN pip install runpod websocket-client librosa

# Por si algun paquete anterior volvio a subir huggingface_hub: se re-fija al final
RUN pip install "huggingface_hub>=1.5.0,<2.0"

# Falla en el BUILD (no en runtime) si transformers no importa
RUN python -c "import transformers, huggingface_hub; print('transformers', transformers.__version__, '| hub', huggingface_hub.__version__)"

ENV HF_HUB_ENABLE_HF_TRANSFER=1

WORKDIR /

# Modelos - Qwen-Image-2.1 (Comfy-Org)
RUN hf download Comfy-Org/Qwen-Image-2.1 diffusion_models/qwen_image_2.1_int8_convrot.safetensors --local-dir /tmp/hf_dl && \
    mv /tmp/hf_dl/diffusion_models/qwen_image_2.1_int8_convrot.safetensors /ComfyUI/models/diffusion_models/
RUN hf download Comfy-Org/Qwen-Image-2.1 text_encoders/qwen3vl_8b_int8_convrot.safetensors --local-dir /tmp/hf_dl && \
    mv /tmp/hf_dl/text_encoders/qwen3vl_8b_int8_convrot.safetensors /ComfyUI/models/text_encoders/
RUN hf download Comfy-Org/Qwen-Image-2.1 vae/qwen_image_2.1_vae_bf16.safetensors --local-dir /tmp/hf_dl && \
    mv /tmp/hf_dl/vae/qwen_image_2.1_vae_bf16.safetensors /ComfyUI/models/vae/ && \
    rm -rf /tmp/hf_dl

COPY . .

# Normaliza finales de linea (CRLF -> LF) por si los archivos vienen de Windows
RUN sed -i 's/\r$//' /entrypoint.sh /handler.py && chmod +x /entrypoint.sh

CMD ["/entrypoint.sh"]
