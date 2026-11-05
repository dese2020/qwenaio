# Imagen base con CUDA 13 y ComfyUI ya instalado en /ComfyUI
FROM hearmeman/comfyui-minimax-template:v9 AS runtime

# wget (descarga de modelos / imagenes por URL) y curl (healthcheck del entrypoint)
RUN apt-get update && apt-get install -y wget curl && rm -rf /var/lib/apt/lists/*

# IMPORTANTE: NO usar "-U". huggingface_hub 2.x rompe transformers (exige >=1.5.0,<2.0)
RUN pip install "huggingface_hub[hf_transfer]>=1.5.0,<2.0"
RUN pip install runpod websocket-client librosa

WORKDIR /

# ComfyUI ya viene en la imagen base: NO se vuelve a clonar ni a instalar requirements
# (reinstalarlos podria reemplazar el torch con CUDA 13).
# KJNodes: se clona solo si la imagen base no lo trae.
RUN cd /ComfyUI/custom_nodes/ && \
    if [ ! -d ComfyUI-KJNodes ]; then git clone https://github.com/kijai/ComfyUI-KJNodes; fi && \
    cd ComfyUI-KJNodes && \
    pip install --no-cache-dir -r requirements.txt

# Re-fija huggingface_hub por si algun requirements anterior lo subio a 2.x
RUN pip install "huggingface_hub>=1.5.0,<2.0"

# Falla en el BUILD (no en runtime) si torch/transformers no importan
RUN python -c "import torch, transformers, huggingface_hub; print(\"torch\", torch.__version__, \"| cuda\", torch.version.cuda, \"| transformers\", transformers.__version__, \"| hub\", huggingface_hub.__version__)"

# Modelos (los mismos de la version 1)
RUN mkdir -p /ComfyUI/models/diffusion_models /ComfyUI/models/text_encoders /ComfyUI/models/vae /ComfyUI/models/loras
RUN wget -q https://huggingface.co/Phr00t/Qwen-Image-Edit-Rapid-AIO/resolve/main/v23/Qwen-Rapid-AIO-NSFW-v23.safetensors -O /ComfyUI/models/diffusion_models/Qwen-Rapid-AIO-NSFW-v23.safetensors
RUN wget -q https://huggingface.co/Comfy-Org/Qwen-Image_ComfyUI/resolve/main/split_files/text_encoders/qwen_2.5_vl_7b_fp8_scaled.safetensors -O /ComfyUI/models/text_encoders/qwen_2.5_vl_7b_fp8_scaled.safetensors
RUN wget -q https://huggingface.co/Comfy-Org/Qwen-Image_ComfyUI/resolve/main/split_files/vae/qwen_image_vae.safetensors -O /ComfyUI/models/vae/qwen_image_vae.safetensors

COPY . .

# Normaliza finales de linea (CRLF -> LF) por si los archivos vienen de Windows
RUN sed -i 's/\r$//' /entrypoint.sh /handler.py && chmod +x /entrypoint.sh

CMD ["/entrypoint.sh"]
