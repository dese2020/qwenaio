# Use specific version of nvidia cuda image
FROM hearmeman/comfyui-minimax-template:v8 as runtime

# wget 설치 (URL 다운로드를 위해)
RUN apt-get update && apt-get install -y wget && rm -rf /var/lib/apt/lists/*

RUN pip install -U "huggingface_hub[hf_transfer]"
RUN pip install runpod websocket-client librosa
ENV HF_HUB_ENABLE_HF_TRANSFER=1

# Set working directory
WORKDIR /

# NOTA: la imagen base ya incluye ComfyUI instalado en /ComfyUI.
# Se elimina el git clone previo para no pisar la instalación del template.
# Si tu imagen base NO trae ComfyUI, descomenta este bloque:
# RUN git clone https://github.com/comfyanonymous/ComfyUI.git && \
#     cd ComfyUI && \
#     pip install --no-cache-dir -r requirements.txt

#RUN cd /ComfyUI/custom_nodes/ && \
#    git clone https://github.com/kijai/ComfyUI-KJNodes && \
#    cd ComfyUI-KJNodes && \
#    pip install --no-cache-dir -r requirements.txt

# Download models - Qwen-Image-2.1 (Comfy-Org)
RUN hf download Comfy-Org/Qwen-Image-2.1 diffusion_models/qwen_image_2.1_int8_convrot.safetensors --local-dir /tmp/hf_dl && \
    mv /tmp/hf_dl/diffusion_models/qwen_image_2.1_int8_convrot.safetensors /ComfyUI/models/diffusion_models/
RUN hf download Comfy-Org/Qwen-Image-2.1 text_encoders/qwen3vl_8b_int8_convrot.safetensors --local-dir /tmp/hf_dl && \
    mv /tmp/hf_dl/text_encoders/qwen3vl_8b_int8_convrot.safetensors /ComfyUI/models/text_encoders/
RUN hf download Comfy-Org/Qwen-Image-2.1 vae/qwen_image_2.1_vae_bf16.safetensors --local-dir /tmp/hf_dl && \
    mv /tmp/hf_dl/vae/qwen_image_2.1_vae_bf16.safetensors /ComfyUI/models/vae/ && \
    rm -rf /tmp/hf_dl

COPY . .
RUN chmod +x /entrypoint.sh

CMD ["/entrypoint.sh"]
